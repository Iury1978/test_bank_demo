require 'json'
require 'watir'
require 'nokogiri'

class Main

  attr_accessor :browser, :accounts
 
  def initialize
    @browser = Watir::Browser.new :chrome
  end
  
  def start
    goto_bank_page
    account_ids
    
  end

  def goto_bank_page
  browser.goto('demo.bank-on-line.ru')
  browser.window.maximize
  # sleep 5
  browser.div(text: 'Войти').wait_until(&:present?).click
    # вывел все заголовки таблицы / class: DList
    # puts browser.dl(class: 'tabs').wait_until(&:present?).text

    # попытался нажать на второй элемент в таблице(массиве)- не дает, но текст выводит
    # browser.dl(css: 'tabs').parent.dds[1].click

    # закрываю окошко насчет смены пароля
  browser.element(css: '#changePwdLater').wait_until(&:present?).click
  browser.div(data_layout: 'navbar').wait_until(&:present?).click
  sleep 10
  end

# получаем список номеров аккаунтов, которые будем перебирать в parse_accounts
  def account_ids
    # browser.div(data_semantic: "accounts-list"))
    #  можно и так, так мне понятнее, что щелкаем
#  проходим мапом по всем ссылкам,  и берем аттрибут :data_contract_r_id], получаем массив 
#  айди аккаунтов, который записывается в account_ids
    account_ids = browser.lis.map do |li|
      li.attributes[:data_contract_r_id]
    end
    # удаляю ненужные элементы из массива( все нилы, повторяющиеся и не соответствующие параметрам счета)
    account_ids.uniq!.compact!
    account_ids.delete_if {|n| n.size != 20}
    puts account_ids
  end
# sleep 5

end
 Main.new.start
