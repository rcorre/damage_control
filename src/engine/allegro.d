module engine.allegro;

// library setup
pragma(lib, "dallegro5");
version(none)
{

}
else
{
	pragma(lib, "allegro");
	pragma(lib, "allegro_primitives");
	pragma(lib, "allegro_image");
	pragma(lib, "allegro_font");
	pragma(lib, "allegro_ttf");
	pragma(lib, "allegro_color");
	pragma(lib, "allegro_audio");
	pragma(lib, "allegro_acodec");
}

// make all allegro functions available
public import allegro5.allegro;
public import allegro5.allegro_primitives;
public import allegro5.allegro_image;
public import allegro5.allegro_font;
public import allegro5.allegro_ttf;
public import allegro5.allegro_color;
public import allegro5.allegro_audio;
public import allegro5.allegro_acodec;

package void allegroInitAll() {
  al_init();
  al_install_keyboard();
  al_install_mouse();
  al_install_joystick();
  al_install_audio();
  al_init_primitives_addon();
  al_init_acodec_addon();
  al_init_image_addon();
  al_init_font_addon();
  al_init_ttf_addon();
}
