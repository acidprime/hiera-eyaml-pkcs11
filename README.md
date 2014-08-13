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

This gem has three operational modes.

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
/opt/puppet/bin/eyaml encrypt \
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
/opt/puppet/bin/eyaml encrypt \
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

# Openssl mode

This mode uses the openssl gem to allow for offline encryption to take place using just the export rsa public key.

### Typical parameters

| Configuration file parameter | Command line parameter | Description             |
| ---------------------------  | ---------------------- | ----------------------- |
| public_key                   | --pkcs11-public_key    | Path to public PEM file |

```shell
/opt/puppet/bin/eyaml encrypt \
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

## Contributing

1. Fork it ( https://github.com/[my-github-username]/hiera-eyaml-pkcs11/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
