module sqlgui;

import std.stdio;
import std.path;

import mysql.d;

import gtk.Builder;
import gtk.Main;
import gtk.Window;
import gtk.Widget;
import gtk.TreeView;
import gtk.TreeViewColumn;
import gtk.ListStore;
import gtk.ToolButton;
import gtk.CellRendererText;
import gtk.Statusbar;

import gsv.SourceView;
import gsv.SourceBuffer;
import gsv.SourceLanguage;
import gsv.SourceLanguageManager;
import gsv.SourceStyleSchemeManager;

int main(string[] args)
{
    Main.init(args);

    auto client  = new Mysql("localhost", "root", null, "companies");
    auto builder = new Builder();
    auto path    = absolutePath("../src/views/main_window.glade");

    builder.addFromFile(path);

    auto window = cast(Window) builder.getObject("main_window");
    auto editor = cast(SourceView) builder.getObject("sql_editor");
    auto tview  = cast(TreeView) builder.getObject("sql_results");

    auto status         = cast(Statusbar) builder.getObject("statusbar");
    auto status_context = status.getContextId("status");

    auto buffer           = editor.getBuffer();
    auto language_manager = new SourceLanguageManager();
    auto language         = language_manager.getLanguage("sql");
    auto scheme_manager   = new SourceStyleSchemeManager();
    auto scheme           = scheme_manager.getScheme("solarized-light");

    auto run_button = cast(ToolButton) builder.getObject("toolbar_run");

    run_button.addOnClicked(delegate void(ToolButton b)
    {
        status.push(status_context, "Running query...");

        auto sql_result  = client.query(buffer.getText());
        auto field_names = sql_result.fieldNames();

        GType[] types                = [];
        TreeViewColumn[] columns     = [];
        TreeViewColumn[] old_columns = [];

        // Gather and remove the existing columns.
        for ( auto i = 0; i < tview.getNColumns(); i++ )
        {
            old_columns ~= tview.getColumn(i);
        }

        foreach ( column ; old_columns )
        {
            tview.removeColumn(column);
        }

        foreach ( field ; field_names )
        {
            auto index    = sql_result.getFieldIndex(field);
            auto column   = new TreeViewColumn();
            auto renderer = new CellRendererText();

            // GTK is dumb as a brick and uses "_" for keyboard accelerators. To
            // allow literal underscores you have to use two of them. It also
            // makes total sense to use `std.array.replace` for string
            // replacements but that's apparently the way to go in D.
            column.setTitle(std.array.replace(field, "_", "__"));

            column.packStart(renderer, 0);
            column.addAttribute(renderer, "text", index);
            column.setResizable(true);

            types   ~= GType.STRING;
            columns ~= column;
        }

        auto list = new ListStore(types);

        foreach ( column ; columns )
        {
            tview.appendColumn(column);
        }

        foreach ( row ; sql_result )
        {
            auto iter = list.createIter();

            foreach ( field ; field_names )
            {
                auto index = sql_result.getFieldIndex(field);

                list.setValue(iter, index, row[field]);
            }
        }

        tview.columnsAutosize();
        tview.setModel(list);

        status.pop(status_context);
    });

    buffer.setLanguage(language);
    buffer.setHighlightSyntax(true);
    buffer.setStyleScheme(scheme);

    editor.modifyFont("DejaVu Sans Mono", 10);

    window.addOnDestroy(delegate void(Widget w) { Main.quit(); });

    window.showAll();
    Main.run();

    return 0;
}
