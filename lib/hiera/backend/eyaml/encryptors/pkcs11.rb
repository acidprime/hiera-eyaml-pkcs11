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

            :slot_id => { :desc    => "The slot to use for the session",
                            :type    => :integer,
                            :default => 4 },

            :key_label => { :desc    => "The label of the public/private key to use",
                            :type    => :string,
                            :default => "badkeyname" },

            :offline => { :desc    => "Work in offline mode using offline publickey",
                          :type    => :boolean,
                          :default => false },

            :offline_publickey => { :desc    => "Local path to the Public key used in offline mode",
                                    :type    => :string,
                                    :default => "/etc/puppetlabs/puppet/ssl/keys/pkcs11.publickey.pem" },


            :hsm_library => { :desc    => "HSM Shared object library path",
                              :type    => :string,
                              :default => "/opt/nfast/toolkits/pkcs11/libcknfast.so" },


            :hsm_usertype => { :desc    => "HSM Softcard user type CKU_<foo>",
                               :type    => :string,
                               :default => "#{:USER}" },

            :hsm_password => { :desc    => "HSM Softcard Password",
                               :type    => :string,
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
	    key_label     = self.option :key_label
            slot_id       = self.option :slot_id

            pkcs11 = PKCS11.open(hsm_library)

            # Convert slotid from Human to array value
            pkcs11.active_slots[(slot_id - 1 )].open do |session|
              session.login(hsm_usertype,hsm_password)
              
              public_key  = session.find_objects(:CLASS => PKCS11::CKO_PUBLIC_KEY).select { |obj| obj[:LABEL] == key_label}.first
              private_key = session.find_objects(:CLASS => PKCS11::CKO_PRIVATE_KEY).select { |obj| obj[:LABEL] == key_label}.first
             
              if action == :encrypt
                result = session.encrypt(:RSA_PKCS,public_key,text)
              elsif action == :decrypt
                result = session.decrypt(:RSA_PKCS,private_key,text)
              end
              session.logout
              result
            end
          end

          def self.create_keys
              #    pub_key, priv_key = session.generate_key_pair(:RSA_PKCS_KEY_PAIR_GEN,
              #          {:MODULUS_BITS=>2048, :PUBLIC_EXPONENT=>[3].pack("N"), :TOKEN=>false},
              #                {})
             raise StandardError, "Not implemented"
          end
         end
      end
    end
  end
end
