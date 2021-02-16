class Transaction

attr_accessor :date, :amount, :currency, :description, :account_name

  def initialize(parameters)
  	@date = parameters[:date]
    @amount = parameters[:amount]
    @currency = parameters[:currency]
    @description = parameters[:description]
    @account_name = parameters[:account_name]
  end
  
end
