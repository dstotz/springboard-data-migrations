require '../lib/inventory_qty_importer'
require 'springboard-retail'
require 'logger'

SPRINGBOARD_SUBDOMAIN = ''
SPRINGBOARD_TOKEN = ''

LOG = Logger.new(STDOUT)

inventory_qty_file = ARGV.first || abort('Missing inventory qty file')

client = Springboard::Client.new(
  "https://#{SPRINGBOARD_SUBDOMAIN}.myspringboard.us/api",
  token: SPRINGBOARD_TOKEN
)

InventoryQtyImporter.new(inventory_qty_file, client).import
