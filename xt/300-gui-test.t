use v6;
#use lib '../gtk-v3/lib';
use Test;

use Gnome::Gtk3::Glade;
use Gnome::Gtk3::Glade::Engine;

use Gnome::Gtk3::Main;
use Gnome::Gtk3::Widget;
use Gnome::Gtk3::TextView;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Label;

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
  method exit-program ( ) {
#`{{
    diag "quit-program called";
    diag "Widget: " ~ $widget.perl if ?$widget;
    diag "Data: " ~ $data.perl if ?$data;
    diag "Object: " ~ $object.perl if ?$object;
}}
#note "LL 1c: ", gtk_main_level();
    self.glade-main-quit();
#note "LL 1d: ", gtk_main_level();
  }

  #-----------------------------------------------------------------------------
  method copy-text ( ) {

#note "copy text thread: $*THREAD.id()";
    my Str $text = self.glade-clear-text('inputTxt');
    self.glade-add-text( 'outputTxt', $text);
  }

  #-----------------------------------------------------------------------------
  method clear-text ( ) {

#note "clear text thread: $*THREAD.id()";
    self.glade-clear-text('outputTxt');
  }
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
class T does Gnome::Gtk3::Glade::Engine::Test {

  #-----------------------------------------------------------------------------
  submethod BUILD ( ) {
    # Wait for start
    $!steps = [
      :!ignore-wait,
      :step-wait(1.5),

      # Set text of input widget
      :set-text(
        :widget-id<inputTxt>,
        :widget-class<Gnome::Gtk3::TextView>,
        :text("text voor invoer\n"),
      ),

      # Test Copy button
      :emit-signal(
        :widget-id<copyBttn>,
        :widget-class<Gnome::Gtk3::Button>,
        :signal-name<clicked>,
      ),

      # Check if text is copied to output widget
      :get-text(
        :widget-id<outputTxt>,
        :widget-class<Gnome::Gtk3::TextView>,
      ),
      :do-test( {
          is $!test-value, "text voor invoer\n", 'Text found is same as input';
        }
      ),

      # Repeat test of Copy button
      :set-text(
        :widget-id<inputTxt>,
        :widget-class<Gnome::Gtk3::TextView>,
        :text("2e text\n"),
      ),
      :emit-signal(
        :widget-id<copyBttn>,
        :widget-class<Gnome::Gtk3::Button>,
        :signal-name<clicked>,
      ),
      :get-text(
        :widget-id<outputTxt>,
        :widget-class<Gnome::Gtk3::TextView>,
      ),
      :do-test( {
          is $!test-value, "text voor invoer\n2e text\n",
             'Text is appended properly';
        }
      ),

      # Test Clear button
      :emit-signal(
        :widget-id<clearBttn>,
        :widget-class<Gnome::Gtk3::Button>,
        :signal-name<clicked>,
      ),
      :get-text(
        :widget-id<outputTxt>,
        :widget-class<Gnome::Gtk3::TextView>,
      ),
      :do-test( {
          is $!test-value, "", 'Text is cleared';
        }
      ),

      # Test Quit button
      :get-main-level,
      :do-test( {
          is $!test-value, 1, 'loop level is 1';
        }
      ),
#      :debug,
      :emit-signal(
        :widget-id<quitBttn>,
        :widget-class<Gnome::Gtk3::Button>,
        :signal-name<clicked>,
      ),
#      :!debug,

#      :wait(3.0),
#      :get-main-level,
#      :do-test( {
#          is $!test-value, 0, 'loop level is 0';
#        }
#      ),

      # Stop tests
      :finish,
    ];
  }
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
#subtest 'Action object', {
  my Gnome::Gtk3::Glade $gui .= new;
  $gui.add-gui-file($file);
  $gui.add-engine(E.new);
  $gui.run(:test-setup(T.new()));
#}

#-------------------------------------------------------------------------------
done-testing;

#unlink $file;
#rmdir $dir;
