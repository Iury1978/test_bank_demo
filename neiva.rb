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
        tr = browser.tr(class: ["cp-item", "cp-transaction"], data_transaction_id: "#{transaction_id}").wait_until(&:present?)
        tr.click
        html =  browser.div(id: "divPopups").html
        transaction_information = Nokogiri::HTML.parse(html)
        class_name = tr.attribute_value 'class'
        income = inflow_or_outflow(class_name)
        browser.a(class: 'close-modal').click
        transaction = parse_transaction_information(transaction_information,account_id, income)
      end              
      account.transactions = account_transactions
      # browser.back
      # browser.back
# для наглядности прямой переход на список счетов
      browser.element(css: '#lnkContracts').wait_until(&:present?).click
    end
    full_accounts_information = { accounts: accounts }
    puts JSON.pretty_generate(full_accounts_information)
    # File.new("Neiva_rezult.txt", "w")
    File.open("Neiva_rezult.txt", "w") do |info|
      info.write(JSON.pretty_generate(full_accounts_information))
    end
  end

#                      вспомогательные методы

# метод, в котором получаем список номеров аккаунтов
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
#  этот вариант для списка.
    # account_ids.compact!
    # account_ids.uniq!
    # account_ids.delete_if {|n| n.size != 20}    
  end

# парсим аккаунт
  def parse_account(account_information, account_id)
    @array_text = []

    account_information.css("[class='tdFieldVal']").each do |text|        
      @array_text << text      
    end

    parameters = {
      id: account_id,
      name: @array_text[0].text,
      currency: @array_text[1].text,
      balance: @array_text[4].text.gsub(/[^\d\.]/, ''),
      date_of_creation: @array_text[2].text
    }
    Account.new(parameters)
  end

#  метод получения id всех транзакций каждого счета отдельно
  def get_transaction_ids
    transaction_ids = []
    browser.div(text: "Список операций").wait_until(&:present?).click
    select_2_month_transaction
    transaction_ids = browser.table(class: "cp-tran-with-balance").map do |tr_id|
      tr_id.attributes[:data_transaction_id]
    end
    transaction_ids = transaction_ids.compact!  
  end

# метод обработки каждой отдельной операции
  def parse_transaction_information(transaction_information, account_id, income)
    trs = transaction_information.css('.blockBody')

    transaction = {}
    for tr in trs do
      name = tr.css('td.tdFieldName').text
      value = tr.css('td.tdFieldVal').text
      transaction[name] = value
    end
    if income == true
      amount_transaction = (transaction['Сумма операции'].gsub(/[^\d\.]/, '').to_f)
    else
      amount_transaction = (transaction['Сумма операции'].gsub(/[^\d\.]/, '').to_f) * (-1)
    end
    transaction = Transaction.new(
      description:  transaction['Описание'],
      amount:       amount_transaction,
      currency:     transaction['Сумма операции'][-1],
      date:         Date.parse(transaction['Дата обработки']),
      account_name: account_id
    )
  end

# метод выборки  транзакций по заданному интервалу
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

# метод проверки приход или расход по наличию класса cp-income
  def inflow_or_outflow(class_name)
    if class_name.include? 'cp-income' 
      income = true
    else
      income = false
    end
  end

end     

Neiva.new.start