{% set postgresql = salt["pillar.get"]("postgresql") %}

wal-e-dependencies:
  pkg.installed:
    - pkgs:
      - daemontools
      - lzop
      - pv
      - python-gevent
      - python-boto
      - python-swiftclient
      - python-keystoneclient

wal-e:
  pkg.installed:
    - sources:
      - python-wal-e: salt://postgresql/server/packages/python-wal-e_0.7.2-2_all.deb
    - require:
      - pkg: wal-e-dependencies


/etc/wal-e.d:
  file.directory:
    - user: root
    - group: postgres
    - mode: 750


/etc/wal-e.d/WALE_SWIFT_PREFIX:
  file.managed:
    - contents: "{{ pillar['wal-e']['swift-prefix'] }}/{{ grains['fqdn'] }}"
    - user: root
    - group: postgres
    - mode: 640
    - require:
      - file: /etc/wal-e.d


/etc/wal-e.d/SWIFT_AUTHURL:
  file.managed:
    - contents_pillar: wal-e:swift-authurl
    - user: root
    - group: postgres
    - mode: 640
    - require:
      - file: /etc/wal-e.d


/etc/wal-e.d/SWIFT_REGION:
  file.managed:
    - contents_pillar: wal-e:swift-region
    - user: root
    - group: postgres
    - mode: 640
    - require:
      - file: /etc/wal-e.d


/etc/wal-e.d/SWIFT_USER:
  file.managed:
    - contents_pillar: wal-e:swift-user
    - user: root
    - group: postgres
    - mode: 640
    - require:
      - file: /etc/wal-e.d


/etc/wal-e.d/SWIFT_PASSWORD:
  file.managed:
    - contents_pillar: wal-e:swift-password
    - user: root
    - group: postgres
    - mode: 640
    - require:
      - file: /etc/wal-e.d


/etc/wal-e.d/WALE_GPG_KEY_ID:
  file.managed:
    - contents_pillar: wal-e:gpg-key-id
    - user: root
    - group: postgres
    - mode: 640
    - require:
      - file: /etc/wal-e.d


/var/lib/postgresql/wal-e.gpg:
  file.managed:
    - contents_pillar: wal-e:gpg-key
    - user: root
    - group: postgres
    - mode: 644
    - require:
      - pkg: postgresql-server


wal-e-gpg-key:
  cmd.wait:
    - name: gpg --import /var/lib/postgresql/wal-e.gpg
    - user: postgres
    - watch:
      - file: /var/lib/postgresql/wal-e.gpg


wal-e-initial-backup:
  cmd.run:
    - name: 'SWIFT_TENANT="{{ salt["pillar.get"]("wal-e:swift-tenant") }}" envdir /etc/wal-e.d backup-push && touch /var/lib/postgresql/wal-e.initial'
    - user: postgres
    - unless: ls /var/lib/postgresql/wal-e.initial
    - require:
      - service: postgresql-server
      - pkg: wal-e
      - cmd: wal-e-gpg-key
      - file: {{ postgresql.config_dir }}/conf.d
      - file: /etc/wal-e.d/WALE_SWIFT_PREFIX
      - file: /etc/wal-e.d/SWIFT_AUTHURL
      - file: /etc/wal-e.d/SWIFT_REGION
      - file: /etc/wal-e.d/SWIFT_USER
      - file: /etc/wal-e.d/SWIFT_PASSWORD
      - file: /etc/wal-e.d/WALE_GPG_KEY_ID