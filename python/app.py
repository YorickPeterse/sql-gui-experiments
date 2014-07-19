from gi.repository import Gtk, GtkSource, GObject, Pango
from os import path
import psycopg2

client = psycopg2.connect('dbname=reddit_stats user=postgres')

GObject.type_register(GtkSource.View)

builder = Gtk.Builder()
dirname = path.dirname(__file__)
path = path.abspath(path.join(dirname, 'views/main_window.glade'))

builder.add_from_file(path)

window = builder.get_object('main_window')
editor = builder.get_object('sql_editor')
tview = builder.get_object('sql_results')

status = builder.get_object('statusbar')
status_context = status.get_context_id('status')

buffer = editor.get_buffer()
language_manager = GtkSource.LanguageManager()
language = language_manager.get_language('sql')
scheme_manager = GtkSource.StyleSchemeManager()
scheme = scheme_manager.get_scheme('solarized-light')

buffer.set_language(language)
buffer.set_highlight_syntax(True)
buffer.set_style_scheme(scheme)

editor.modify_font(Pango.FontDescription.from_string('DejaVu Sans Mono 10'))

run_button = builder.get_object('toolbar_run')

def run_callback(button):
    status.push(status_context, 'Running query...')

    cursor = client.cursor()
    start = buffer.get_start_iter()
    stop = buffer.get_end_iter()

    cursor.execute(buffer.get_text(start, stop, True))

    result = cursor.fetchall()

    types = []
    columns = []
    column_names = [desc[0] for desc in cursor.description]

    if tview.get_n_columns() > 0:
        for column in tview.get_columns():
            tview.remove_column(column)

    for index, name in enumerate(column_names):
        column = Gtk.TreeViewColumn()
        renderer = Gtk.CellRendererText()

        column.set_title(name.replace('_', '__'))

        column.pack_start(renderer, False)
        column.add_attribute(renderer, 'text', index)
        column.set_resizable(True)

        types.append(str)
        columns.append(column)

    list = Gtk.ListStore(*types)

    for column in columns:
        tview.append_column(column)

    for row in result:
        iter = list.append()

        for index, name in enumerate(column_names):
            list.set_value(iter, index, str(row[index]))

    tview.columns_autosize()
    tview.set_model(list)

    status.remove_all(status_context)

run_button.connect('clicked', run_callback)

window.connect('destroy', Gtk.main_quit)

window.show_all()
Gtk.main()
