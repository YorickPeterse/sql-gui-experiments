require 'gir_ffi-gtk3'
require 'pg'

GirFFI.setup :GtkSource

Gtk.init

client = PG.connect(
  :user   => 'postgres',
  :dbname => 'reddit_stats'
)

builder = Gtk::Builder.new
path    = File.expand_path('../views/main_window.glade', __FILE__)

builder.add_from_file(path)

window = builder.get_object('main_window')
editor = builder.get_object('sql_editor')
tview  = builder.get_object('sql_results')

status         = builder.get_object('statusbar')
status_context = status.get_context_id('status')

buffer           = editor.get_buffer
language_manager = GtkSource::LanguageManager.new
language         = language_manager.get_language('sql')
scheme_manager   = GtkSource::StyleSchemeManager.new
scheme           = scheme_manager.get_scheme('solarized-light')

buffer.language         = language
buffer.highlight_syntax = true
buffer.style_scheme     = scheme

editor.modify_font(Pango::FontDescription.from_string('DejaVu Sans Mono 10'))

run_button = builder.get_object('toolbar_run')

run_button.signal_connect('clicked') do
  status.push(status_context, 'Running query...')

  result  = client.exec(buffer.text.chomp(';'))
  types   = []
  columns = []

  # Gather and remove the existing columns.
  if tview.get_n_columns > 0
    tview.get_columns.each do |column|
      tview.remove_column(column)
    end
  end

  result.fields.each_with_index do |name, index|
    column   = Gtk::TreeViewColumn.new
    renderer = Gtk::CellRendererText.new

    # TODO: handle multiple underscores
    column.title = name.gsub('_', '__')

    column.pack_start(renderer, false)
    column.add_attribute(renderer, 'text', index)
    column.resizable = true

    types   << GObject::TYPE_STRING
    columns << column
  end

  list = Gtk::ListStore.new(types)

  columns.each { |col| tview.append_column(col) }

  result.each do |row|
    iter = list.append

    result.fields.each_with_index do |name, index|
      list.set_value(iter, index, row[name])
    end
  end

  tview.columns_autosize
  tview.set_model(list)

  status.remove_all(status_context)
end

window.signal_connect('destroy') do
  Gtk.main_quit
end

window.show_all
Gtk.main
