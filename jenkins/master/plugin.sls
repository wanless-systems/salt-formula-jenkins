{% from "jenkins/map.jinja" import master with context %}

{{ master.home }}/updates:
  file.directory:
  - user: jenkins
  - group: {{ master.nongroup }}

setup_jenkins_cli:
  cmd.run:
  # TODO: Remove this sleep 300 - The reason for this is that Jenkins has to
  # download the plugin json information first before it can install plugins.
  # So upon first installing Jenkins you'll get a problem with installing the
  # plugins because it doesn't have the necessary information to run
  - names:
    - wget http://localhost:{{ master.http.port }}/jnlpJars/jenkins-cli.jar && sleep 300
  - unless: "[ -f /root/jenkins-cli.jar ]"
  - cwd: /root
  - require:
    - cmd: jenkins_service_running

{%- for plugin in master.plugins %}

install_jenkins_plugin_{{ plugin.name }}:
  cmd.run:
  - name: >
      java -jar jenkins-cli.jar -s http://localhost:{{ master.http.port }} -http -auth admin:{{ master.user.admin.password }} install-plugin {{ plugin.name }} -deploy -restart &&
      sleep 120
  - unless: "[ -d {{ master.home }}/plugins/{{ plugin.name }} ]"
  - cwd: /root
  - require:
    - cmd: setup_jenkins_cli
    - cmd: jenkins_service_running

# TODO: The Jenkins service *must* be restarted after plugins are installed.
# As we're doing this stuff via the command line this is not automatically done for us.
{%- endfor %}

{%- if master.configuration_as_code_yaml is defined %}
install_jenkins_yaml_configuration_as_code:
    file.managed:
        - name: {{ master.home }}/jenkins.yaml
        - user: root
        - group: root
        - mode: 644
        - contents_pillar: jenkins:master:configuration_as_code_yaml
        - require:
            - install_jenkins_plugin_configuration-as-code

restart_jenkins_after_yaml_configuration:
    cmd.run:
        - name: systemctl restart jenkins && touch /var/lib/jenkins/.restarted
        - unless:
            - test -f /var/lib/jenkins/.restarted
        - require:
            - install_jenkins_yaml_configuration_as_code
{%- endif %}
