require 'json'

class Transaction

  attr_accessor :date, :amount, :currency, :description, :account_name

  def initialize(parameters)
  	@date = parameters[:date]
    @amount = parameters[:amount]
    @currency = parameters[:currency]
    @description = parameters[:description]
    @account_name = parameters[:account_name]
  end
  
  def to_json(*a)
  	{
      amount: @amount,
      currency: @currency,
      description: @description,
  	  account_name: @account_name,
  	  date: @date
  	}.to_json(*a)
  end

end
