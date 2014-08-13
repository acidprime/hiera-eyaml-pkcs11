# Hiera::Eyaml::Pkcs11

This gem adds an encryptor called pkcs11 to the hiera eyaml utility.
It was designed to be used with a Thales nshield connect. It can communicate
with the HSM using pkcs11 via the pkcs11 gem or chil by shelling out to the 
openssl binaries. The different operation modes were designed to be as 
forward compatible as possible when using Puppet Enterprise 3.4 and higher.
Native gems with C extensions in jruby which will be the stack calling hiera
as soon as that JVM master is included in Puppet Enterprise.

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


## Usage

This gem has three operational modes.

1. "pkcs11" mode
This mode uses the pkcs11 shared object libraries to natively communicate with the hsm using pkcs11.

2. "chil" mode
This mode uses the "chil" engine support in the openssl cli to preload a given softcard using the passphase.

3. "openssl" mode
This mode uses the openssl gem to allow for offline encryption to take place using just the export rsa public key.

#PKCS11 mode
### Typical parameters
|Configuration file parameter|Command line parameter |Description             |
|key_label                   |--pkcs11-key-label     | Pubic/Private key label|
|hsm_password                |--pkcs11-hsm-password  | Passphrase for softcard|

### Optional parameters
|Configuration file parameter|Command line parameter |Description             |
|hsm_usertype                |--pkcs11-hsm-user      |"USER" or "SO" no prefix|
|hsm_slot_id                 |--pkcs11-hsm-slot-id   |Slot id of the softcard |
|hsm_library                 |--pkcs11-hsm-library   | Path to HSM .so  file  |

### Example Usage
```shell
/opt/puppet/bin/eyaml encrypt \
-s 'mysecrettext' \
--encrypt-method pkcs11 \
--pkcs11-mode pkcs11 \
--pkcs11-key-label 'puppet-hiera-uat-key' \
--pkcs11-hsm-password 'Thi$$is@rellyl0ngp@$$phase'
```

#CHIL mode
### Typical parameters
|Configuration file parameter|Command line parameter |Description             |
|chil_softcard               |--pkcs11-chil-softcard |Name of softcard to use |
|chil_rsakey                 |--pkcs11-chil-rsakey   |Name of rsa key to use  |
|hsm_password                |--pkcs11-hsm-password  |Passphrase for softcard |


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

# Openssl mode
`--pkcs11-mode openssl`
### Typical parameters
|Configuration file parameter|Command line parameter |Description             |
|public_key               |--pkcs11-public_key       |Path to public PEM file |

```shell
/opt/puppet/bin/eyaml encrypt \
-s 'mysecrettext' \
--encrypt-method pkcs11 \
--pkcs11-mode openssl \
--pkcs11-public-key ~/puppet-hiera-uat-pub.pem
```




## Contributing

1. Fork it ( https://github.com/[my-github-username]/hiera-eyaml-pkcs11/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
