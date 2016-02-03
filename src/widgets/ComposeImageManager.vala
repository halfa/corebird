/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2013 Timm Bäder
 *
 *  corebird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  corebird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */

class ComposeImageManager : Gtk.Container {
  private Gee.ArrayList<AddImageButton> buttons;
  private Gee.ArrayList<Gtk.Button>      close_buttons;

  public int n_images {
    get {
      return this.buttons.size;
    }
  }

  public signal void image_removed ();

  construct {
    this.buttons = new Gee.ArrayList<AddImageButton> ();
    this.close_buttons = new Gee.ArrayList<Gtk.Button> ();
    this.set_has_window (false);
  }

  private void remove_clicked_cb (Gtk.Button source) {
    int index = this.close_buttons.index_of (source);
    assert (index >= 0);

    AddImageButton aib = (AddImageButton) this.buttons.get (index);
    aib.deleted.connect (() => {
      this.buttons.remove_at (index);
      this.close_buttons.remove_at (index);
      this.image_removed ();
      this.queue_draw ();
    });

    aib.start_remove ();
  }

  // GtkContainer API {{{
  public override void forall_internal (bool include_internals, Gtk.Callback cb) {
    assert (buttons.size == close_buttons.size);
    for (int i = 0, p = buttons.size; i < p; i ++) {
      cb (buttons.get (i));
      cb (close_buttons.get (i));
    }
  }

  public override void add (Gtk.Widget widget) {
    widget.set_parent (this);
    widget.set_parent_window (this.get_window ());
    this.buttons.add ((AddImageButton)widget);
    var btn = new Gtk.Button.from_icon_name ("window-close-symbolic");
    btn.set_parent (this);
    btn.get_style_context ().add_class ("image-button");
    btn.get_style_context ().add_class ("close-button");
    btn.clicked.connect (remove_clicked_cb);
    btn.show ();
    this.close_buttons.add (btn);
  }

  public override void remove (Gtk.Widget widget) {
    widget.unparent ();
    int index = 0;
    if (widget is AddImageButton)
      this.buttons.remove ((AddImageButton)widget);
    else
      this.close_buttons.remove ((Gtk.Button)widget);
  }
  // }}}

  // GtkWidget API {{{
  public override Gtk.SizeRequestMode get_request_mode () {
    return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
  }

  public override void size_allocate (Gtk.Allocation allocation) {
    const int MIN_BUTTON_WIDTH  = 100;
    const int MIN_BUTTON_HEIGHT = 100;

    Gtk.Allocation child_allocation = {};
    this.set_allocation (allocation);

    if (this.buttons.size == 0) return;

    child_allocation.x = allocation.x;
    child_allocation.y = allocation.y + 10;
    child_allocation.width = allocation.width / buttons.size;
    //child_allocation.height = int.max (allocation.height - 10, 0);
    child_allocation.height = allocation.height;

    Gtk.Allocation close_allocation = {};
    close_allocation.y = allocation.y;
    for (int i = 0, p = this.buttons.size; i < p; i ++) {
      int imp;
      int min, nat;

      AddImageButton aib = this.buttons.get (i);
      aib.get_preferred_width_for_height (allocation.height, out min, out nat);

      message ("Natural button width: %d for height %d", nat, allocation.height);
      message ("Minimum button width: %d", min);
      int width = int.min (nat, allocation.width / buttons.size);

      child_allocation.width = width;
      //child_allocation.width = int.max (width, MIN_BUTTON_WIDTH);
      //child_allocation.height = int.max (child_allocation.height, MIN_BUTTON_HEIGHT);
      //message ("size: %d, %d", child_allocation.width, child_allocation.height);
      aib.size_allocate (child_allocation);


      //int m, n;
      //Gtk.Widget btn = this.close_buttons.get (i);
      //btn.get_preferred_width (out close_allocation.width, out n);
      //btn.get_preferred_height (out close_allocation.height, out n);
      //close_allocation.x = child_allocation.x + child_allocation.width
                           //- close_allocation.width + 10;
      //btn.size_allocate (close_allocation);

      child_allocation.x += child_allocation.width;
    }
  }

  public override void get_preferred_height_for_width (int width,
                                                       out int minimum,
                                                       out int natural) {
    int min = 0;
    int nat = 0;
    foreach (var btn in this.buttons) {
      int m, n;
      btn.get_preferred_height_for_width (width, out m, out n);
      min = int.max (int.max (m, min), 100);
      nat = int.max (int.max (n, nat), 100);
    }

    minimum = min;
    natural = nat;
  }

  public override void get_preferred_width (out int minimum,
                                            out int natural) {
    int min = 0;
    int nat = 0;
    foreach (var btn in this.buttons) {
      int m, n;
      btn.get_preferred_width (out m, out n);
      min += m;
      nat += n;
    }

    minimum = min;
    natural = nat;
  }

  public override bool draw (Cairo.Context ct) {
    for (int i = 0, p = this.buttons.size; i < p; i ++) {
      Gtk.Widget btn = this.buttons.get (i);
      this.propagate_draw (btn, ct);
    }

    for (int i = 0, p = this.close_buttons.size; i < p; i ++) {
      var btn = this.close_buttons.get (i);
      this.propagate_draw (btn, ct);
    }

    return Gdk.EVENT_PROPAGATE;
  }
  // }}}

  public void load_image (string path) {
    Cairo.ImageSurface surface = (Cairo.ImageSurface) load_surface (path);

    var button = new AddImageButton ();
    button.surface = surface;
    button.image_path = path;

    button.hexpand = false;
    button.halign = Gtk.Align.START;
    button.show ();
    this.add (button);
  }

  public string[] get_image_paths () {
    var paths = new string[this.buttons.size];

    int i = 0;
    foreach (var btn in this.buttons) {
      paths[i] = btn.image_path;
      i ++;
    }

    return paths;
  }

  public void start_progress (string image_path) {
    foreach (var btn in this.buttons) {
      if (btn.image_path == image_path) {
        btn.get_style_context ().add_class ("image-progress");
        break;
      }
    }
  }

  public void end_progress (string image_path, string? error_message) {
    foreach (var btn in this.buttons) {
      if (btn.image_path == image_path) {
        btn.get_style_context ().remove_class ("image-progress");

        if (error_message == null) {
          btn.get_style_context ().add_class ("image-success");
        } else {
          warning ("%s: %s", image_path, error_message);
          btn.get_style_context ().add_class ("image-error");
        }
        break;
      }
    }
  }
}
