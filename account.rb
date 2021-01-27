class Account

attr_accessor :name, :currency, :balance, :date_of_creation , :transactions

  def initialize(parameters)
    @name = parameters[:name]
    @currency = parameters[:currency]
    @balance = parameters[:balance]
    @date_of_creation = parameters[:date_of_creation]
    @transactions = []
  end
  
end