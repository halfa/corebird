/*  This file is part of corebird.
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
using Gtk;

[GtkTemplate (ui = "/org/baedert/corebird/ui/account-info-widget.ui")]
class AccountInfoWidget : Gtk.Grid {
  [GtkChild]
  private Switch always_notify_switch;
  [GtkChild]
  private Label screen_name_label;
  [GtkChild]
  private Label name_label;

  private unowned Account account;

  public AccountInfoWidget (Account acc) {
    this.account = acc;
    screen_name_label.label = acc.screen_name;
    name_label.label = acc.name;
  }

  [GtkCallback]
  private void open_window_clicked () {
    message ("open window clicked");
  }
}
