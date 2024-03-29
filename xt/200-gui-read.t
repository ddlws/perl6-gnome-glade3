use v6;
#use lib '../perl6-gnome-gobject/lib', '../perl6-gnome-gtk3/lib';
use Test;
use NativeCall;

use Gnome::Gtk3::Glade;

use Gnome::N::X;
use Gnome::N::N-GObject;
use Gnome::Gdk3::Types;
use Gnome::Gdk3::EventTypes;
use Gnome::Gdk3::Keysyms;
use Gnome::Gtk3::Main;
use Gnome::Gtk3::Widget;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Label;
use Gnome::Gtk3::Window;

X::Gnome.debug(:on);

#-------------------------------------------------------------------------------
diag "\n";

my $dir = 'xt/x';
mkdir $dir unless $dir.IO ~~ :e;

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
my Str $file = "$dir/a.xml";
$file.IO.spurt(Q:q:to/EOXML/);
  <?xml version="1.0" encoding="UTF-8"?>
  <!-- Generated with glade 3.22.1 -->
  <interface>
    <requires lib="gtk+" version="3.10"/>
    <object class="GtkWindow" id="window">
      <property name="visible">True</property>
      <property name="can_focus">False</property>
      <property name="border_width">10</property>
      <property name="title">Grid</property>
      <child>
        <placeholder/>
      </child>
      <child>
        <object class="GtkGrid" id="grid">
          <property name="visible">True</property>
          <property name="can_focus">False</property>
          <property name="row_spacing">6</property>
          <property name="column_spacing">6</property>
          <child>
            <object class="GtkLabel" id="inputTxtLbl">
              <property name="visible">True</property>
              <property name="can_focus">False</property>
              <property name="label" translatable="yes">Text to copy</property>
              <property name="justify">right</property>
              <property name="single_line_mode">True</property>
              <attributes>
                <attribute name="foreground" value="#f1f1a5fff0a0"/>
                <attribute name="background" value="#05058f8fa0a0"/>
              </attributes>
            </object>
            <packing>
              <property name="left_attach">0</property>
              <property name="top_attach">1</property>
            </packing>
          </child>
          <child>
            <object class="GtkTextView" id="inputTxt">
              <property name="visible">True</property>
              <property name="can_focus">True</property>
              <!--signal name="insert-at-cursor" handler="insert-char" swapped="no"/-->
            </object>
            <packing>
              <property name="left_attach">1</property>
              <property name="top_attach">1</property>
              <property name="width">2</property>
            </packing>
          </child>
          <child>
            <object class="GtkButton" id="clearBttn">
              <property name="label" translatable="yes">Clear Text</property>
              <property name="visible">True</property>
              <property name="can_focus">True</property>
              <property name="receives_default">True</property>
              <signal name="clicked" handler="clear-text" swapped="no"/>
            </object>
            <packing>
              <property name="left_attach">0</property>
              <property name="top_attach">2</property>
            </packing>
          </child>
          <child>
            <object class="GtkButton" id="copyBttn">
              <property name="label">Copy Text</property>
              <property name="visible">True</property>
              <property name="can_focus">False</property>
              <property name="receives_default">False</property>
              <signal name="clicked" handler="copy-text" swapped="no"/>
            </object>
            <packing>
              <property name="left_attach">1</property>
              <property name="top_attach">2</property>
            </packing>
          </child>
          <child>
            <object class="GtkButton" id="quitBttn">
              <property name="label">Quit</property>
              <property name="visible">True</property>
              <property name="can_focus">False</property>
              <property name="receives_default">False</property>
              <signal name="clicked" handler="exit-program" swapped="no"/>
            </object>
            <packing>
              <property name="left_attach">2</property>
              <property name="top_attach">2</property>
            </packing>
          </child>
          <child>
            <object class="GtkScrolledWindow" id="ScrolledOutputTxt">
              <property name="width_request">200</property>
              <property name="height_request">300</property>
              <property name="visible">True</property>
              <property name="can_focus">True</property>
              <property name="shadow_type">in</property>
              <property name="max_content_width">200</property>
              <property name="max_content_height">300</property>
              <child>
                <object class="GtkTextView" id="outputTxt">
                  <property name="width_request">200</property>
                  <property name="height_request">300</property>
                  <property name="visible">True</property>
                  <property name="can_focus">True</property>
                  <property name="wrap_mode">word</property>
                </object>
              </child>
            </object>
            <packing>
              <property name="left_attach">0</property>
              <property name="top_attach">0</property>
              <property name="width">3</property>
            </packing>
          </child>
        </object>
      </child>
    </object>
  </interface>
  EOXML

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
class E is Gnome::Gtk3::Glade::Engine {

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {
    my Gnome::Gtk3::Window $w .= new(:build-id<window>);
#$w.debug(:on);

    # the easy way
    $w.register-signal(
      self, 'keyboard-event', 'key-press-event', :time(now)
    );

    $w.register-signal(
      self, 'enter-leave-event', 'enter-notify-event', :time(now)
    );

    $w.register-signal(
      self, 'enter-leave-event', 'leave-notify-event', :time(now)
    );

    # the difficult way
    my Callable $handler;
    $handler =
      -> N-GObject $ignore-w, GdkEvent $e, OpaquePointer $ignore-d {
        self.mouse-event( :widget($w), :event($e) );
      };

    $w.connect-object( 'button-press-event', $handler);
  }

  #-----------------------------------------------------------------------------
  method mouse-event ( :widget($window), GdkEvent :$event ) {

    $window.debug(:on);
    my GdkEventType $t = GdkEventType($event.event-any.type);
    note "\nevent type: $t";
    my GdkEventButton $event-button := $event.event-button;
    note "x, y: ", $event-button.x, ', ', $event-button.y;
    note "Root x, y: ", $event-button.x_root, ', ', $event-button.y_root;
    for 0,1,2,4,8 ... 2**(32-1) -> $m {
      if $event-button.state +& $m {
        note "Found in state: ", GdkModifierType($m);
      }
    }

    note "Button: ", $event-button.button;
  }

  #-----------------------------------------------------------------------------
  method enter-leave-event ( :widget($window), GdkEvent :$event ) {

#    $window.debug(:on);
    note "\nevent type: ", GdkEventType($event.event-any.type);
    my GdkEventCrossing $event-crossing := $event.event-crossing;
    note "x, y: ", $event-crossing.x, ', ', $event-crossing.y;
    note "Root x, y: ", $event-crossing.x_root, ', ', $event-crossing.y_root;

    note "Mode: ", GdkCrossingMode($event-crossing.mode);
    note "Detail: ", GdkNotifyType($event-crossing.detail);
  }

  #-----------------------------------------------------------------------------
  method keyboard-event ( :widget($window), GdkEvent :$event, :$time ) {

#    $window.debug(:on);
    my GdkEventKey $event-key := $event.event-key;
    note "\nevent type: ", GdkEventType($event-key.type);
    note "state: ", $event-key.state.base(2);
    for 0,1,2,4,8 ... 2**(32-1) -> $m {
      if $event-key.state +& $m {
        note "Found in state: ", GdkModifierType($m);
      }
    }

    note "key: ", $event-key.keyval.fmt('0x%04x');
    note "Return pressed" if $event-key.keyval == GDK_KEY_Return;
    note "KP Enter pressed" if $event-key.keyval == GDK_KEY_KP_Enter;

    note "hw key: ", $event-key.hardware_keycode;
  }

  #-----------------------------------------------------------------------------
  method exit-program ( ) {

    self.glade-main-quit();
  }

  #-----------------------------------------------------------------------------
  method copy-text ( :$widget ) {
#$widget.debug(:on);

    my Str $text = self.glade-clear-text('inputTxt');
    self.glade-add-text( 'outputTxt', $text);
  }

  #-----------------------------------------------------------------------------
  method clear-text ( :$widget ) {
#$widget.debug(:on);

    note self.glade-clear-text('outputTxt');
  }
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
subtest 'Action object', {

  my Gnome::Gtk3::Glade $gui .= new;
  isa-ok $gui, Gnome::Gtk3::Glade, 'type ok';
  $gui.add-gui-file($file);
  $gui.add-engine(E.new);
  $gui.run;
}

#-------------------------------------------------------------------------------
done-testing;

unlink $file;
rmdir $dir;
