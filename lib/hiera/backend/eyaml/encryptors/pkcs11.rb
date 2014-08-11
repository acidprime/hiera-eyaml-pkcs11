require 'base64'
require 'hiera/backend/eyaml/encryptor'
require 'hiera/backend/eyaml/utils'
require 'hiera/backend/eyaml/options'
require "rubygems"
require "pkcs11"


class Hiera
  module Backend
    module Eyaml
      module Encryptors
        class Pkcs11 < Encryptor
          include PKCS11
          self.options = {

            :offline_publickey => { :desc => "Local path to the Public key used in offline mode",
                                    :type => :string,
                                    :default => "/etc/puppetlabs/puppet/ssl/keys/pkcs11.publickey.pem" },

            :hsm_mechanism => { :desc => "Key generation mechanism",
                                :type => :string,
                                :default => :DES2_KEY_GEN },

            :hsm_library => { :desc => "HSM Shared object library",
                              :type => :string,
                              :default => "/opt/nfast/toolkits/pkcs11/libcknfast.so" },


            :hsm_usertype => { :desc => "HSM Softcard user type CKU_<foo>",
                               :type => :string,
                               :default => :USER },

            :hsm_password => { :desc => "HSM Softcard Password",
                               :type => :string,
                               :default => "badpassword" },
          }

          self.tag = "PKCS11"

          def self.encrypt plaintext
             self.session(:encrypt,plaintext)
          end

          def self.decrypt ciphertext
             self.session(:decrypt,ciphertext)
          end

          def self.session(action,text)

            hsm_usertype  = self.option :hsm_usertype
            hsm_password  = self.option :hsm_password
            hsm_library   = self.option :hsm_library
            hsm_mechanism = self.option :hsm_mechanism
            raise StandardError, "hsm_usertype is not defined"  unless hsm_usertype
            raise StandardError, "hsm_password is not defined"  unless hsm_password
            raise StandardError, "hsm_library is not defined"   unless hsm_library

            pkcs11 = PKCS11.open(hsm_library)
            p pkcs11.info  # => #<PKCS11::CK_INFO cryptokiVersion=...>
            pkcs11.active_slots.first.open do |session|
              session.login(hsm_username,hsm_password)
              secret_key = session.generate_key(
                hsm_mechanism,
                :ENCRYPT=>true,
                :DECRYPT=>true,
                :SENSITIVE=>true,
                :TOKEN=>true,
                :LABEL=>"#{Time.Now}")
              if action == :encrypt
                result = session.encrypt( {:DES3_CBC_PAD=>"\0"*8}, secret_key,text)
              elsif action == :decrypt
                result = session.decrypt( {:DES3_CBC_PAD=>"\0"*8}, secret_key,text)
              end
              session.logout
              result
            end
          end

          def self.create_keys
              #    pub_key, priv_key = session.generate_key_pair(:RSA_PKCS_KEY_PAIR_GEN,
              #          {:MODULUS_BITS=>2048, :PUBLIC_EXPONENT=>[3].pack("N"), :TOKEN=>false},
              #                {})
             raise StandardError "Not implemented"
          end
         end
      end
    end
  end
end
