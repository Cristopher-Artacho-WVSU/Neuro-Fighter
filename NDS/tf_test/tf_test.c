#include "gdextension_interface.h"
#include "tensorflow/c/c_api.h"
#include <stdio.h>

#define PROJECT_NAME "tf_test"

// void init_gd_module(void *p_userdata, GDExtensionInitializationLevel p_level)
// {
//   if (p_level != GDEXTENSION_INITIALIZATION_SCENE) {
//     return;
//   }
// }
// void deinit_gd_module(void *p_userdata,
//                       GDExtensionInitializationLevel p_level) {}
// [[gnu::visibility("default")]] GDExtensionBool
// gd_example(const GDExtensionInterfaceGetProcAddress p_get_proc_addr,
//            const GDExtensionClassLibraryPtr p_library,
//            GDExtensionInitialization *r_init) {
//   r_init->initialize = init_gd_module;
//   r_init->deinitialize = deinit_gd_module;
//   r_init->userdata = NULL;
//   r_init->minimum_initialization_level = GDEXTENSION_INITIALIZATION_SCENE;
//   return true;
// }

int main(int argc, char **argv) {
  if (argc != 1) {
    printf("%s takes no arguments.\n", argv[0]);
    return 1;
  }
  printf("This is project %s.\n", PROJECT_NAME);
  printf("Hello from Tensorflow C! (%s)", TF_Version());
  auto graph = TF_NewGraph();
  auto status = TF_NewStatus();
  auto session_opts = TF_NewSessionOptions();
  const char *model_dir = "../nds";
  const char *tags[] = {"serve"};

  TF_Buffer *run_opts = NULL;
  auto session = TF_LoadSessionFromSavedModel(session_opts, run_opts, model_dir,
                                              tags, 1, graph, NULL, status);
  if (TF_GetCode(status) != TF_OK) {
    fprintf(stderr, "Error loading model: %s\n", TF_Message(status));
    return EXIT_FAILURE;
  }
  return 0;
}
