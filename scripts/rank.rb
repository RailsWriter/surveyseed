#!/usr/bin/ruby

class Rank

  def initialize (ranking)
    if ranking == 1 then @rank='True RANK'
    else
      @rank='Fake RANK'
    end
  end
end