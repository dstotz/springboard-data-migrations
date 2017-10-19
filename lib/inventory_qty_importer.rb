require '../lib/physical_count'
require 'csv'
require 'progress_bar'

class InventoryQtyImporter
  def initialize(inventory_qty_file, client, reason_name: 'Initial Import')
    @import_file = CSV.read(inventory_qty_file, headers: true)
    @springboard = client
    @reason_name = reason_name
    @inventory_counts = Hash.new { |hash, key| hash[key] = Hash.new(0) }
  end

  def import
    process_import_file
    @inventory_counts.each do |location, items|
      count = create_physical_count(location)
      if count
        LOG.info "Adding items to physical count for location #{location}"
        add_items_to_count(count, items)
        count.complete
      end
    end
  end

  private

  def add_items_to_count(count, items)
    bar = ProgressBar.new items.count
    items.each do |item_num, qty|
      count.add(item_num, qty)
      bar.increment!
    end
  end

  def create_physical_count(location)
    begin
      location_id = @springboard[:locations].filter(public_id: location).first.id
      count = PhysicalCount.new(@springboard, location_id, reason_code)
    rescue
      LOG.error "Failed to create physical count for location #{location}, skipping this location"
      return nil
    end
  end

  def process_import_file
    @import_file.each do |line|
      @inventory_counts[line['Location']][line['Item #']] += line['Qty'].to_f
    end
  end

  def reason_code
    @reason_code ||= find_reason_code
  end

  def find_reason_code
    begin
      @springboard[:reason_codes][:inventory_adjustment_reasons].filter(name: @reason_name).first.id
    rescue
      LOG.error "Unable to find #{@reason_name} reason code"
    end
  end
end
