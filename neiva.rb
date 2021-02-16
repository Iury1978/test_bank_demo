require 'json'
require 'watir'
require 'nokogiri'
require_relative 'account'
require_relative 'transaction'

class Neiva
  attr_accessor :browser, :accounts
  def initialize
    @browser = Watir::Browser.new :chrome
    @accounts = []
    @array_text = []
  end

  def start
    goto_bank_page
    parse_accounts
    parse_transactions
  end

  def goto_bank_page
    browser.goto('demo.bank-on-line.ru')
    browser.window.maximize
# sleep 5
    browser.div(text: 'Войти').wait_until(&:present?).click
# закрываю окошко насчет смены пароля, раньше его не было, пришлось добавить строчку/опять пропала. скрываю
# browser.element(css: '#changePwdLater').wait_until(&:present?).click
# для получения списка аккантов из списка. часто тормозит и сделал для получения id из таблицы
    browser.div(data_layout: 'navbar').wait_until(&:present?).click
    sleep 5
  end

  def parse_accounts
    browser.element(css: '#lnkContracts').wait_until(&:present?).click
    get_account_ids.map do |account_id|
      browser.tr(data_c_r_id: /#{account_id}/).wait_until(&:present?).click
      html =  browser.table(crid: /#{account_id}/).wait_until(&:present?).html
      account_information = Nokogiri::HTML.parse(html)
      @accounts << parse_account(account_information, account_id) 
      browser.back
      #  -----------------------------находимся в списке счетов--------------------------
    end
  end
 
  def parse_transactions    
# в цикле обхожу каждый аккаунт
    @accounts.each do |account|
    browser.tr(data_c_r_id: /#{account.id}/).wait_until(&:present?).click
      account_transactions = get_transaction_ids.map do |transaction_id|
      account_id = account.id
# вот тут надо распределить где приход, а где расход
# browser.tr(class: ["cp-item", "cp-transaction", "cp-income"], data_transaction_id: "#{transaction_id}").wait_until(&:present?).click
      browser.tr(class: ["cp-item", "cp-transaction"], data_transaction_id: "#{transaction_id}").wait_until(&:present?).click
      html =  browser.div(id: "divPopups").html
      transaction_information = Nokogiri::HTML.parse(html)
#  начинаем парсить каждую транзакцию
      browser.a(class: 'close-modal').click
      parse_transaction_information(transaction_information,account_id)
      end              
    account.transactions = account_transactions
    browser.back
    browser.back
    end
    # puts parsed_all_accounts
    full_accounts_information = { accounts: parsed_all_accounts }
    # puts full_accounts_information
    # выводит все в строку
    # puts full_accounts_information.to_json
    # выводит как по заданию
    puts JSON.pretty_generate(full_accounts_information)
    # File.new("Neiva_rezult.txt", "w")
    File.open("Neiva_rezult.txt", "w") do |info|
      info.write(JSON.pretty_generate(full_accounts_information))
      end
  end

#                      вспомогательные методы(может, их сделать приватными?)


# получаем список номеров аккаунтов
  def get_account_ids
    # ID из списка
    # account_ids = browser.lis.map do |li|
    #   li.attributes[:data_contract_r_id]
    # end
    #  ID из таблицы
    browser.element(css: '#lnkContracts').wait_until(&:present?).click
      account_ids = browser.table(id: "contracts-list").map do |acc_id|
      acc_id.attributes[:data_c_r_id]
      end
    account_ids.compact!
    account_ids     
# удаляю ненужные элементы из массива( все нилы, повторяющиеся и не соответствующие параметрам счета)
#  этот вариант для списка.
    # account_ids.compact!
    # account_ids.uniq!
    # account_ids.delete_if {|n| n.size != 20}    
  end

  def parse_account(account_information, account_id)
    account_information.css("[class='tdFieldVal']").each do |text|        
      @array_text << text      
      end
    name1 = @array_text[0].text
    currency1 = @array_text[1].text
    balance1 = @array_text[4].text.gsub(/[^\d\.]/, '')
    date_of_creation1 = @array_text[2].text
    @array_text = []
      Account.new(
      name: name1,
      currency: currency1,
      balance: balance1,
      date_of_creation: date_of_creation1,
      id: account_id
      )    
  end

  def get_transaction_ids
    transaction_ids = []
    browser.div(text: "Список операций").wait_until(&:present?).click
    select_2_month_transaction
    transaction_ids = browser.table(class: "cp-tran-with-balance").map do |tr_id|
      tr_id.attributes[:data_transaction_id]
      end
    transaction_ids = transaction_ids.compact!  
  end

  def parse_transaction_information(transaction_information,account_id)
    one_transaction = []
    transaction_text = []
    transaction_information.css("[class='tdFieldVal']").each do |text|        
      transaction_text << text      
      end

    date = transaction_text[5].text
# формат данных 50.00 ₽    поэтому из одной строки беру данные для 2 позиций
    amount = transaction_text[2].text.gsub(/[^\d\.]/, '')
    currency = transaction_text[2].text[-1]

      if transaction_text[-1].to_s.include? 'p__number'
        description = transaction_text[-2].text
      else
        description = transaction_text[-1].text
      end
    transaction =  Transaction.new(
      date: date,
      amount: amount,
      currency: currency,
      description: description,    
      account_name: account_id
    )
    one_transaction << transaction
      info_in_massive = one_transaction.map do |transaction|
      {
      date: transaction.date,
      amount: transaction.amount,
      currency: transaction.currency,
      description: transaction.description,    
      account_name: transaction.account_name
      }    
      end
  #  формат info_in_massive [{:date=>"11.02.2021 и тд}], поэтому передаю первый элемент массива
    info_in_massive[0]
  end

  def select_2_month_transaction
# специально выбираю + 1 месяц, потому что на сайте месяца от 0 до 11 (value = 0 Январь ,  а в Date январь 1)
  select_today_year  = Date.today.year
  select_2_month_ago = Date.today.prev_month(3).mon
  select_today_date  = Date.today.mday 
  
  browser.div(class: "wrapper-input").wait_until(&:present?).click
  field_before_year = browser.select_list class: "ui-datepicker-year"

      if Date.today.mon == 1 || Date.today.mon == 2
      field_before_year.select "#{select_today_year - 1}"
      else
      field_before_year.select "#{select_today_year}"  
      end

  field_before = browser.select_list class: "ui-datepicker-month"
  field_before.select "#{select_2_month_ago}"
  browser.td(text: "#{select_today_date}").click
  browser.span(data_action: "get-transactions").wait_until(&:present?).click
  end
 
  def parsed_all_accounts
    accounts.map do |account|
      {
        name: account.name,
        currency: account.currency,
        balance: account.balance,
        date_of_creation: account.date_of_creation,
        transactions: account.transactions
      }
    end
  end 

  
end
 Neiva.new.start