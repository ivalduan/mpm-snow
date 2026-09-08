#ifndef MAIN_H
#define	MAIN_H

#include <GLFW/glfw3.h>
#include <iostream>
#include <stdlib.h>
#include <stdio.h>
#include <thread>
#include <time.h>
#ifndef _WIN32
#include <unistd.h>
#endif
#include <math.h>
#include "Particle.h"
#include "PointCloud.h"
#include "Grid.h"
#include "SimConstants.h"
#include "Shape.h"

#if SCREENCAST
#include <stb_image_write.h>
#ifdef _WIN32
#include <direct.h>
#define snow_mkdir(dir) _mkdir(dir)
#else
#include <sys/stat.h>
#define snow_mkdir(dir) mkdir((dir), 0777)
#endif
#endif

float TIMESTEP;

static void error_callback(int, const char*);
void key_callback(GLFWwindow*, int, int, int, int);
void mouse_callback(GLFWwindow*, int, int, int);
void redraw();
void start_simulation();
void *simulate(void *args);
float adaptive_timestep();
void save_buffer(int time);

//Shape stuff
void create_new_shape();
void remove_all_shapes();
Shape* generateSnowball(Vector2f origin, float radius);

#endif

