require 'hiera/backend/eyaml/encryptor'
require 'hiera/backend/eyaml/utils'
require 'hiera/backend/eyaml/options'
require "rubygems"

class Hiera
  module Backend
    module Eyaml
      module Encryptors
        class Pkcs11 < Encryptor
          self.options = {

            :mode    => { :desc    => "What mode <pkcs11|chil|openssl> should be used to (de|en)crypt the values",
                          :type    => :string,
                          :default => 'chil' },

            :slot_id => { :desc    => "The slot to use for the session",
                          :type    => :integer,
                          :default => 4 },

            :key_label => { :desc    => "The label of the public/private key to use",
                            :type    => :string,
                            :default => "badkeylabel" },

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
                               :default => "USER" },

            :hsm_password => { :desc    => "HSM Softcard Password",
                               :type    => :string,
                               :default => "badpassword" },
          }

          self.tag = "PKCS11"

          def self.encrypt(plaintext)
            
             self.checksize(plaintext)
             
             case self.option(:mode)
             when 'chil'
               result = self.chil(:encrypt,plaintext)
             when 'pkcs11'
               result = self.session(:encrypt,plaintext)
             else
               raise "Invalid mode specified #{self.option(:mode)}"
             end
             result
          end

          def self.decrypt(ciphertext)
             case self.option(:mode)
             when 'chil'
               result = self.chil(:decrypt,ciphertext)
             when 'pkcs11'
               result = self.session(:decrypt,ciphertext)
             else
               raise "Invalid mode specified #{self.option(:mode)}"
             end
             result
          end


          def self.checksize(text)
            # This limit seems to be within one byte of either methodology
            if text.bytesize > 244
              raise "Byte limit exceeded ( #{text.bytesize} > 244 )"
            end
          end


          def self.wait_for_prompt(cout)
            buffer = ""
            begin
            loop { buffer << cout.getc.chr; break if buffer =~ /Enter pass phrase:/}
            rescue
            end
            return buffer
          end


          def self.chil(action,text)
            require 'pty'
            require 'shellwords'
            require 'base64'

            hsm_password  = self.option :hsm_password

            encrypt = "echo #{Shellwords.shellescape(text)} |
            /opt/nfast/bin/ppmk --preload puppet-hiera-uat /usr/bin/openssl rsautl \
             -engine chil \
            -inkey rsa-puppethierauatkey \
            -keyform engine \
            -encrypt | /usr/bin/base64"
            
            decrypt = "echo #{Shellwords.shellescape(Base64.encode64(text))} | base64 -d |
            /opt/nfast/bin/ppmk --preload puppet-hiera-uat /usr/bin/openssl rsautl \
             -engine chil \
            -inkey rsa-puppethierauatkey \
            -keyform engine \
            -decrypt"

            if action == :encrypt
               command = encrypt 
               regex   = /(.*engine "chil" set\..*\n)([\r\n\S]+)/ 
            elsif action == :decrypt
               command = decrypt 
               regex   = /(.*engine "chil" set\..*\n)(.*(\n.*)+)/
            end 
            
            PTY.spawn(command) do |openssl_out,openssl_in,pid|
              self.wait_for_prompt(openssl_out)
              openssl_in.printf("#{hsm_password}\n")
              output = self.wait_for_prompt(openssl_out)
              if match = output.match(regex)
                header,cryptogram = match.captures
                cryptogram = Base64.decode64(cryptogram) if action == :encrypt
              else
                raise "Unable to parse output:\n #{output}"
              end
              return cryptogram 
            end
          end

          def self.session(action,text)

            require "pkcs11"
            include PKCS11

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

              raise "No public key found for label #{key_label}" if public_key.nil?
              raise "No private key found for label #{key_label}" if private_key.nil?

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
