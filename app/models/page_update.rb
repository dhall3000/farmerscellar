class PageUpdate < ApplicationRecord
  
  def self.get_update_time(page_name)

    update_time = nil

    db_entry = PageUpdate.find_by(name: "News")
    if db_entry
      update_time = db_entry.update_time
    end
    
    return update_time

  end

end