use inc::Module::Install;

all_from    "lib/DBICx/Schema/YAML.pm";

requires    "YAML::Tiny"    => 0;
requires    "DBIx::Class"   => 0;
requires    "File::Slurp"   => 0;

WriteAll;
