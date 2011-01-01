use Module::Build;

Module::Build->new(
    module_name     => "DBICx::Schema::YAML",
    all_from        => "lib/DBICx/Schema/YAML.pm",
    requires        => {
        "DBIx::Class"       => 0,
        "YAML::XS"          => 0,
        "File::Slurp"       => 0,
        "Scalar::Util"      => 0,
    },
    license         => "bsd",
    meta_merge      => {
        resources => {
            repository => "http://github.com/mauzo/DBICx-Schema-YAML",
        },
    },
)->create_build_script;
