require 'json'
require 'watir'
require 'nokogiri'
require_relative 'account'
class Neiva

  attr_accessor :browser, :accounts
  def initialize
    @browser = Watir::Browser.new :chrome
    @account_ids = []
    @array_text = []
  end

  def start
    goto_bank_page
    @account_ids = get_account_ids  
    parse_accounts
    # parse_account
  end

  def goto_bank_page
  browser.goto('demo.bank-on-line.ru')
  browser.window.maximize
  # sleep 5
  browser.div(text: 'Войти').wait_until(&:present?).click
    # закрываю окошко насчет смены пароля, раньше его не было, пришлось добавить строчку
  browser.element(css: '#changePwdLater').wait_until(&:present?).click
  browser.div(data_layout: 'navbar').wait_until(&:present?).click
  sleep 2
  end

# получаем список номеров аккаунтов
  def get_account_ids
    account_ids = browser.lis.map do |li|
      li.attributes[:data_contract_r_id]
    end
# удаляю ненужные элементы из массива( все нилы, повторяющиеся и не соответствующие параметрам счета)
    account_ids.compact!
    account_ids.uniq!
    account_ids.delete_if {|n| n.size != 20}
    # puts account_ids
    # account_ids
  end

  def parse_accounts
    browser.element(css: '#lnkContracts').wait_until(&:present?).click
    @accounts = []
    @account_ids.map do |account_id|
      browser.tr(data_c_r_id: /#{account_id}/).wait_until(&:present?).click
      html =  browser.table(crid: /#{account_id}/).wait_until(&:present?).html
      account_information = Nokogiri::HTML.parse(html)
# puts account_information
       accounts << parse_account(account_information, account_id)  
      browser.back
    end
# проверил -puts accounts.to_s выдаст [#<Account:0x000055fd1f56aa78 @name="Счёт RUB", @currency="Российский рубль", @balance="1000000.00",
# @date_of_creation="01.01.2020", @transactions=[]>, #<Account:0x000055fd1f432138 @name="Счёт USD", @currency="Доллар США",
# @balance="100000.00", @date_of_creation="01.01.2020", @transactions=[]>, 
#<Account:0x000055fd1f5374c0 @name="Счёт EUR", @currency="Евро", @balance="100000.00", @date_of_creation="01.01.2020", @transactions=[]>]

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
         # puts name1
         # puts currency1
         # puts balance1
         # puts date_of_creation1
         # puts account_id

  
    
  end

end
 Neiva.new.start
