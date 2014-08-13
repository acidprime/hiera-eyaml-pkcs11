# Hiera::Eyaml::Pkcs11

This gem adds an encryptor called pkcs11 to the hiera eyaml utility.
It was designed to be used with a Thales nshield connect. It can communicate
with the HSM using pkcs11 via the pkcs11 gem or chil by shelling out to the
openssl binaries. The different operation modes were designed to be as
forward compatible as possible when using Puppet Enterprise 3.4 and higher.
Native gems with C extensions in jruby which will be the stack calling hiera
as soon as that JVM master is included in Puppet Enterprise.

You can build this gem using:
    `rake build`


Add this line to your application's Gemfile:

    gem 'hiera-eyaml-pkcs11'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hiera-eyaml-pkcs11

    # If you plan on using pkcs11 support directly
    # This is specified as a development dependency and thus not auto installed
    $ gem install pkcs11

    # If you plan on using the local openssl mode
    # This is specified as a development dependency and thus not auto installed
    # ( Likely already included in your distribution )
    $ gem install openssl


# Usage

This gem has three operational modes: `pkcs11`,`chil` and `openssl`

## PKCS11 mode

This mode uses the pkcs11 shared object libraries to natively communicate with the hsm using pkcs11.

### Typical parameters

| Configuration file parameter | Command line parameter | Description             |
| ---------------------------- | ---------------------- | ----------------------- |
| pkcs11_key_label             | --pkcs11-key-label     | Pubic/Private key label |
| pkcs11_hsm_password          | --pkcs11-hsm-password  | Passphrase for softcard |

### Optional parameters

| Configuration file parameter | Command line parameter | Description              |
| ---------------------------- | ---------------------- | ------------------------ |
| pkcs11_hsm_usertype          | --pkcs11-hsm-user      | "USER" or "SO" no prefix |
| pkcs11_hsm_slot_id           | --pkcs11-hsm-slot-id   | Slot id of the softcard  |
| pkcs11_hsm_library           | --pkcs11-hsm-library   |  Path to HSM .so  file   |

### Example Usage

```shell
eyaml encrypt \
-s 'mysecrettext' \
--encrypt-method pkcs11 \
--pkcs11-mode pkcs11 \
--pkcs11-key-label 'puppet-hiera-uat-key' \
--pkcs11-hsm-password 'Thi$$is@rellyl0ngp@$$phase'
```

### Example hiera.yaml Entry

```yaml
:eyaml:
  :datadir: /etc/puppetlabs/puppet/hiera/%{environment}/
  :pkcs11_mode: 'pkcs11'
  :pkcs11_key_label: 'puppet-hiera-uat-key'
  :pkcs11_hsm_password: 'Thi$$is@rellyl0ngp@$$phase'
  :extension: 'yaml'
```

_Note: The difference of dash vs underscore in the key names_

This mode was tested with:

```
Red Hat Enterprise Linux release 6.5 (Santiago)
Puppet 3.6.2 (Puppet Enterprise 3.3.0)
Hiera Eyaml Gem (2.0.2)
Pkcs11 Gem (0.2.4)
Ruby (1.9.3.3p484)
```

#CHIL mode

This mode uses the "chil" engine support in the openssl cli to preload a given softcard using the passphase.

### Typical parameters

| Configuration file parameter | Command line parameter  | Description             |
| ---------------------------- | ----------------------  | ----------------------- |
| pkcs11_chil_softcard         | --pkcs11-chil-softcard  | Name of softcard to use |
| pkcs11_chil_rsakey           | --pkcs11-chil-rsakey    | Name of rsa key to use  |
| pkcs11_hsm_password          | --pkcs11-hsm-password   | Passphrase for softcard |


### Example Usage

```shell
eyaml encrypt \
-s 'mysecrettext' \
--encrypt-method pkcs11 \
--pkcs11-mode chil \
--pkcs11-chil-softcard 'puppet-hiera-uat' \
--pkcs11-chil-rsakey 'rsa-puppethierauatkey' \
--pkcs11-hsm-password 'Thi$$is@rellyl0ngp@$$phase'
```

### Example hiera.yaml Entry

```yaml
:eyaml:
  :datadir: /etc/puppetlabs/puppet/hiera/%{environment}/
  :pkcs11_mode: 'chil'
  :pkcs11_chil_softcard: 'puppet-hiera-uat'
  :pkcs11_chil_rsakey: 'rsa-puppethierauatkey'
  :pkcs11_hsm_password: 'Thi$$is@rellyl0ngp@$$phase'
  :extension: 'yaml'
```

_Note: The difference of dash vs underscore in the key names_

This mode was tested with:

```
Red Hat Enterprise Linux release 6.5 (Santiago)
Puppet 3.6.2 (Puppet Enterprise 3.3.0)
Hiera Eyaml Gem (2.0.2)
Pkcs11 Gem (0.2.4)
Ruby (1.9.3.3p484)
```

# Openssl mode

This mode uses the openssl gem to allow for offline encryption to take place using just the export rsa public key.

### Typical parameters

| Configuration file parameter | Command line parameter | Description             |
| ---------------------------  | ---------------------- | ----------------------- |
| public_key                   | --pkcs11-public_key    | Path to public PEM file |

```shell
eyaml encrypt \
-s 'mysecrettext' \
--encrypt-method pkcs11 \
--pkcs11-mode openssl \
--pkcs11-public-key ~/puppet-hiera-uat-pub.pem
```

### Example hiera.yaml Entry
```yaml
:eyaml:
  :datadir: /etc/puppetlabs/puppet/hiera/%{environment}/
  :pkcs11_mode: 'openssl'
  :pkcs11_public_key: '/etc/puppetlabs/puppet/ssl/keys/puppet-hiera-uat-pub.pem'
  :extension: 'yaml'
```

_Note: The difference of dash vs underscore in the key names_

#### Linux

This mode was tested with:

```
Red Hat Enterprise Linux release 6.5 (Santiago)
Puppet 3.6.2 (Puppet Enterprise 3.3.0)
Hiera Eyaml Gem (2.0.2)
Pkcs11 Gem (0.2.4)
Ruby (1.9.3.3p484)
```

#### Mac OS X

```
Mac OS X (10.8.5)
hiera-eyaml (2.0.2)
ruby 1.8.7 (2012-02-08 patchlevel 358) [universal-darwin12.0]
```
### Example Puppet Configuration

```puppet

  # Example with chil mode
  # Note the use of ssl instead of "secure" in the pkcs7 path as
  # is the default in the eyaml README file. This is just an example

  $pkcs11_config = [
    ':eyaml:',
    '  :datadir: "/etc/puppetlabs/puppet/environments/%{environment}/"',
    '  :extension: "yaml"',
    '  :encrypt_method: "pkcs11"',
    '  :pkcs11_chil_softcard: "puppet-hiera-uat"',
    '  :pkcs11_chil_rsakey: "rsa-puppethierauatkey"',
    '  :pkcs11_hsm_password: "Thi$$is@rellyl0ngp@$$phase"',
    '  :pkcs7_private_key: "/etc/puppetlabs/puppet/ssl/keys/private_key.pkcs7.pem"',
    '  :pkcs7_public_key: "/etc/puppetlabs/puppet/ssl/keys/public_key.pkcs7.pem"',
  ]

  File {
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
    mode    => '0750',
  }

  # This is an example using http://forge.puppetlabs.com/hunner/hiera
  class { '::hiera':
    backends     => [
      'eyaml',
      'yaml',
    ],
    datadir      => '/etc/puppetlabs/puppet/environments/%{environment}/',
    hierarchy    => [
      'servers/%{::clientcert}',
      '%{environment}',
      'global',
    ],
    extra_config => join($pkcs11_config,"\n"),
    require      => Package['hiera-eyaml'],
  }

  # This should only be used if you have a gem server
  # or access to gem server that has these gems
  package { ['hiera-eyaml','hiera-eyaml-pkcs11']:
    ensure       => installed,
    provider     => 'pe_gem',
    require      => File['gemrc'],
  }

  # Create a global gemrc for Puppet Enterprise to add the local gem source
  # See http://projects.puppetlabs.com/issues/18053#note-12 for more information.
  file { '/opt/puppet/etc':
    ensure => 'directory',
    owner  => 'root',
    group  => '0',
    mode   => '0755',
  }

  file { 'gemrc':
    ensure  => 'file',
    path    => '/opt/puppet/etc/gemrc',
    owner   => 'root',
    group   => '0',
    mode    => '0644',
    content => "---\nupdate_sources: true\n:sources:\n- http://your.internal.gem.server.com/rubygems/\n",
  }

  # This is only required if you want pkcs7 functional as well
  # hiera 1.3 does allow for variable interpolation function
  # calls so you could encrypt pkcs11_hsm_password with pkcs7
  # Note the use of ssl instead of "secure" in the path as
  # is the default in the eyaml README file.

  exec { 'create_keypair':
    user    => 'pe-puppet',
    path    => "${::path}:/opt/puppet/bin",
    cwd     => '/etc/puppetlabs/puppet/ssl',
    command => 'eyaml createkeys',
    creates => '/etc/puppetlabs/puppet/ssl/keys/private_key.pkcs7.pem',
    before  =>  File['/etc/puppetlabs/puppet/ssl/keys'],
    require =>  [ Package['heira-eyaml-pkcs11'], Package['hiera-eyaml']],
  }

```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/hiera-eyaml-pkcs11/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
