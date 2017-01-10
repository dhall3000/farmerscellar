class PageUpdate < ApplicationRecord
  
  def self.get_update_time(page_name)

    update_time = nil

    db_entry = PageUpdate.find_by(name: page_name)
    if db_entry
      update_time = db_entry.update_time
    end
    
    return update_time

  end

  def self.set_update_time(page_name, update_time = Time.zone.now)
    db_entry = PageUpdate.find_by(name: page_name)
    if db_entry
      db_entry.update(update_time: update_time)
    end
  end

end