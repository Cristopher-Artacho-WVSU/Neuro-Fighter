project(
  'tf_test',
  'c',
  meson_version : '>= 1.3.0',
  version : '0.1',
  default_options : [
    'warning_level=3',
    'c_std=c23'
  ],
)

project_root = meson.project_source_root()

tensorflow = declare_dependency(
  include_directories: include_directories('./include'),
  link_args: [
    project_root / 'lib/libtensorflow.so'
  ]
)

gdextension = declare_dependency(
  include_directories: include_directories('./include')
)

dependencies = [
  tensorflow,
  gdextension
]

exe = executable(
  'tf_test',
  'tf_test.c',
  dependencies : dependencies,
  build_rpath : project_root / 'lib'
)

test('basic', exe)
