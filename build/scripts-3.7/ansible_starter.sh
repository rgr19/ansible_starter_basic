#!/bin/bash

CWD=$1

if [ -z "$CWD" ]; then
  echo CWD is empty, set it as PWD="$PWD/ansible_playground"
  CWD="$PWD/ansible_playground"
fi

if [ -d "$CWD" ]; then
  echo "[ABORT] Directory \`$CWD\` already exists."
  exit -1
fi

function ansible_project_directory_structure() {
  mkdir -p $CWD/{group_vars,host_vars,library,module_utils,filter_plugins,files}
  mkdir -p $CWD/inventories/{production,staging,workstation}/{group_vars,host_vars}
  mkdir -p $CWD/roles/common/{tasks,handlers,templates,files,vars,defaults,meta,library,module_utils,lookup_plugins}
  touch $CWD/{main.yml,ansible.cfg}
  touch $CWD/inventories/{production,staging,workstation}/{dynamic.py,static}
  touch $CWD/roles/common/{tasks,handlers,templates,files,vars,defaults,meta}/main.yml
}

function ansible_static_inventories() {
  echo "[workstation]
localhost ansible_connection=local

    " >$CWD/inventories/workstation/static

  echo "[staging_group]

    " >$CWD/inventories/staging/static

  echo "[production_group]

    " >$CWD/inventories/production/static

}

function ansible_config() {
  echo "[defaults]
library = ./library

    " >$CWD/ansible.cfg
}

function ansible_libary_python_hello_world() {
  echo "#!/usr/bin/python

from ansible.module_utils.basic import *


def main():
    module = AnsibleModule(argument_spec={})
    rval = {\"hello\": \"world\"}
    module.exit_json(changed=False, meta=rval)


if __name__ == '__main__':
    main()

    " >$CWD/library/hello_world.py
}

function ansible_library_python_pass_variables() {
  echo "#!/usr/bin/python

from ansible.module_utils.basic import *


def main():

    fields = {
        \"no_to_increment\": {\"default\": True, \"type\": int},
        \"name_to_change\": {\"default\": True, \"type\": str},
        \"description\": {\"default\": True, \"type\": str},
    }

    module = AnsibleModule(argument_spec=fields)
    # change the name
    nameToChange = module.params[\"name_to_change\"]
    module.params.update({\"name_to_change\": nameToChange + \" \" + \"After\"})
    # increment the no
    noToIncrement = module.params[\"no_to_increment\"]
    module.params.update({\"no_to_increment\": noToIncrement + 1})

    module.exit_json(changed=True, meta=module.params)


if __name__ == '__main__':
    main()

    " >$CWD/library/pass_variables.py
}

function ansible_files_bash_hello_world() {
  echo "#!/bin/bash

echo \"[BASH] Hello World (input: '\$@')\"

    " >$CWD/files/hello_world.sh
}

function ansible_main_playbook() {
  echo "---
- hosts: workstation
  post_tasks:
    - name: \"[Bash] 'Hello World' script from files/hello_world.sh that simply echo 'Hello World (input: <all input>)' as output\"
      script: hello_world.sh \"Your Name\" \"Age 21\" \"Dog named Alice\" etc..
      register: result
    - debug: var=result

  roles:
    - { role: common }

  tasks:
    - name: \"[Python] 'Hello World' module from library/hello_world.py that simply returns 'Hello World' as output\"
      hello_world:
      register: result
    - debug: var=result

  pre_tasks:
    - name: \"[Python] 'Pass Variables' module from library/pass_variables.py that gets input, changes it and outputs new values\"
      pass_variables:
        no_to_increment: 111
        name_to_change: Barbara
        description: \"This input will be not modified\"
      register: result
    - debug: var=result

- hosts: staging_group
  roles:
   - { role: common }

- hosts: production_group
  roles:
   - { role: common }

    " >$CWD/main.yml
}

function ansible_roles_common_main_playbook() {
  echo "---
- name: \"Execute 'common' subrole depending on OS FAMILY\"
  block:
    - import_tasks: redhat.yml
      when: ansible_facts['os_family']|lower == 'redhat'
    - import_tasks: debian.yml
      when: ansible_facts['os_family']|lower == 'debian'


- name: \"Collect facts about system services\"
  service_facts:

- debug:
    var: ansible_facts.services|length

    " >$CWD/roles/common/tasks/main.yml
}

function ansible_roles_common_main_debian_playbook() {
  echo "
---
- name: \"[debian] Apt install 'fakeapt' application\"
  block:
    - apt:
        name: fakeapt
        state: present
  rescue:
    - debug:
        msg: 'I caught an error, can do stuff here to fix it, :-)'

    " >$CWD/roles/common/tasks/debian.yml
}

function ansible_roles_common_main_redhat_playbook() {
  echo "
---
- name: \"[redhat] Yum install 'fakeyum' application\"
  block:
    - yum:
        name: fakeyum
        state: present
  rescue:
    - debug:
        msg: 'I caught an error, can do stuff here to fix it, :-)'

    " >$CWD/roles/common/tasks/redhat.yml
}

function ansible_playbook_run_scripts() {
  echo '#!/bin/bash

ANSIBLE_NOCOWS=1 ansible-playbook main.yml -i inventories/workstation $@

    ' >$CWD/workstation_play.sh

  chmod +x $CWD/workstation_play.sh

  echo '#!/bin/bash

ANSIBLE_NOCOWS=1 ansible-playbook main.yml -i inventories/staging $@

    ' >$CWD/staging_play.sh

  chmod +x $CWD/staging_play.sh

  echo '#!/bin/bash

ANSIBLE_NOCOWS=1 ansible-playbook main.yml -i inventories/production $@

    ' >$CWD/production_play.sh

  chmod +x $CWD/production_play.sh
}

function ansible_starter_banner() {
  echo "
# [BANNER] Play ansible main playbook with: ...

## Manually run:

- workstation: ANSIBLE_NOCOWS=1 ansible-playbook main.yml -i inventories/workstation

- staging: ANSIBLE_NOCOWS=1 ansible-playbook main.yml -i inventories/staging

- production: ANSIBLE_NOCOWS=1 ansible-playbook main.yml -i inventories/production

## Run wrapper scripts:

- workstation: ./workstation_play.sh

- staging: ./staging_play.sh

- production: ./production_play.sh

    "
}

echo "# [BEGIN] Setup example ansible project in: \"$CWD\""

echo "...create project structure in: $CWD"
ansible_project_directory_structure

echo "...setup example static inventories"
ansible_static_inventories

echo "...setup example basic config"
ansible_config

echo "...add example modules in $CWD/library"
ansible_libary_python_hello_world
ansible_library_python_pass_variables

echo "...add example scripts in $CWD/files"
ansible_files_bash_hello_world

echo "...add example main.yml playbook in $CWD"
ansible_main_playbook

echo "...add example common role in $CWD/roles"
ansible_roles_common_main_playbook
ansible_roles_common_main_debian_playbook
ansible_roles_common_main_redhat_playbook

echo "...add wrapper run scripts for workstation/staging/production"
ansible_playbook_run_scripts

ansible_starter_banner
