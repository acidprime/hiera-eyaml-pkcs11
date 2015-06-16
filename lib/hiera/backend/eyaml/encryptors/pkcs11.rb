require 'hiera/backend/eyaml/encryptor'
require 'hiera/backend/eyaml/utils'
require 'hiera/backend/eyaml/options'
require "rubygems"
require 'base64'

class Hiera
  module Backend
    module Eyaml
      module Encryptors
        class Pkcs11 < Encryptor
          self.options = {

            :mode          => { :desc    => "What mode <pkcs11|mri-pkcs11|chil|openssl> should be used to (de|en)crypt the values",
                                :type    => :string,
                                :default => 'chil' },

            :key_label     => { :desc    => "The label of the public/private key to use (pkcs11 mode only)",
                                :type    => :string,
                                :default => "badkeylabel" },

            :chil_softcard => { :desc    => "The softcard to preload into chil (chil mode only)",
                                :type    => :string,
                                :default => "badsoftcard" },

            :chil_rsakey   => { :desc    => "The rsa key to use in chil ( chil mode only )",
                                :type    => :string,
                                :default => "badkeylabel" },

            :public_key    => { :desc    => "Local path to the rsa public key (openssl mode only)",
                                :type    => :string,
                                :default => "./keys/public_key.pkcs11.pem" },

            :hsm_slot_id   => { :desc    => "The slot to use for the session (pkcs11 mode only)",
                                :type    => :integer,
                                :default => 4 },

            :hsm_library   => { :desc    => "HSM Shared object library path (pkcs11 mode only)",
                                :type    => :string,
                                :default => "/opt/nfast/toolkits/pkcs11/libcknfast.so" },

            :hsm_usertype  => { :desc    => "HSM Softcard user type CKU_<foo> (pkcs11 mode only)",
                                :type    => :string,
                                :default => "USER" },

            :hsm_password  => { :desc    => "HSM Softcard Password (pkcs11 mode only)",
                                :type    => :string,
                                :default => "badpassword" },
          }

          self.tag = "PKCS11"

          # Eyaml encryptor methods

          def self.encrypt(plaintext)

             self.checksize(plaintext)

             case self.option(:mode)
             when 'chil'
               result = self.chil(:encrypt,plaintext)
             when 'pkcs11'
               result = self.session(:encrypt,plaintext)
             when 'mri-pkcs11'
               result = self.mri_session(:encrypt,plaintext)
             when 'openssl'
               result = self.openssl(:encrypt,plaintext)
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
             when 'mri-pkcs11'
                 result = self.mri_session(:decrypt,ciphertext)
             when 'openssl'
               result = self.openssl(:decrypt,ciphertext)
             else
               raise "Invalid mode specified #{self.option(:mode)}"
             end
             result
          end

          #self.create_keys
          #    #    pub_key, priv_key = session.generate_key_pair(:RSA_PKCS_KEY_PAIR_GEN,
          #    #          {:MODULUS_BITS=>2048, :PUBLIC_EXPONENT=>[3].pack("N"), :TOKEN=>false},
          #    #                {})
          #   raise StandardError, "Not implemented"
          #end

          # Helper methods

          def self.checksize(text)
            # This limit seems to be within one byte of either methodology
            # This is an internal check to stop the trace from the vendor
            # or invalid output in the case of the openssl chil methodology
            if text.bytesize > 244
              raise "Byte limit exceeded ( #{text.bytesize} > 244 )"
            end
          end


          def self.wait_for_prompt(cout)
            # This is based on the output of /opt/nfast/bin/ppmk
            # This will basically allow us to type the passphase in
            # so that the openssl command can continue to use stdin
            buffer = ""
            begin
              loop { buffer << cout.getc.chr; break if buffer =~ /Enter pass phrase:/}
            rescue
            end
            return buffer
          end

          # Mode methods
          def self.chil(action,text)
            require 'pty'
            require 'shellwords'
            require 'base64'

            hsm_password   = self.option :hsm_password
            chil_softcard  = self.option :chil_softcard
            chil_rsakey    = self.option :chil_rsakey

            # TODO: Could turn this into an array and use << as the commands are about the same.

            encrypt = "echo #{Shellwords.shellescape(text)} |
            /opt/nfast/bin/ppmk --preload #{Shellwords.shellescape(chil_softcard)} /usr/bin/openssl rsautl \
             -engine chil \
            -inkey #{Shellwords.shellescape(chil_rsakey)} \
            -keyform engine \
            -encrypt | /usr/bin/base64"

            decrypt = "echo #{Shellwords.shellescape(Base64.encode64(text))} | /usr/bin/base64 -d |
            /opt/nfast/bin/ppmk --preload #{Shellwords.shellescape(chil_softcard)} /usr/bin/openssl rsautl \
             -engine chil \
            -inkey #{Shellwords.shellescape(chil_rsakey)} \
            -keyform engine \
            -decrypt"

            # Scrape the output of the ssl command, in the case of encrypt its a
            # a base64 encoded string, in the case of decryption its everything
            # after the header. This has been tested with multi line input

            if action == :encrypt
               command = encrypt
               regex   = /(.*engine "chil" set\..*\n)([\r\n\S]+)/
            elsif action == :decrypt
               command = decrypt
               regex   = /(.*engine "chil" set\..*\n)(.*(\n.*)?)/
            end

            # Type the passphase in the session and run the command with the
            # stdin being the plaintext or cryptogram. The encrypted value
            # gets wrapped in base64 to help with the shell but as eyaml
            # itself will wrap we decode it and hand back the raw to eyaml
            # , if we are encrypting the value ( decryption is the original)


            PTY.spawn(command) do |openssl_out,openssl_in,pid|
              self.wait_for_prompt(openssl_out)
              openssl_in.printf("#{hsm_password}\n")
              output = self.wait_for_prompt(openssl_out)
              if match = output.match(regex)
                header,cryptogram = match.captures
                cryptogram = Base64.decode64(cryptogram) if action == :encrypt
              else
                raise "Unable to parse output:\n #{output} \n with regex #{regex.to_s}"
              end
              return cryptogram
            end
          end

          def self.session(action,text)
            # This does a direct pkcs11 call through the gem. This will likely not work
            # in Puppet Enterprise 3.4 because gems with native c extentions will not work
            # with jruby and thats what the master will be running when it calls hiera.

            require "pkcs11"
            include PKCS11

            hsm_usertype  = self.option :hsm_usertype
            hsm_password  = self.option :hsm_password
            hsm_library   = self.option :hsm_library
            hsm_slot_id   = self.option :hsm_slot_id

            key_label     = self.option :key_label

            # Load the shared object library from the vendor
            pkcs11 = PKCS11.open(hsm_library)

            # Convert slotid from Human to array value
            pkcs11.active_slots[(hsm_slot_id - 1 )].open do |session|
              session.login(hsm_usertype,hsm_password)


              # Find the public and private key based on their label.
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

          def self.mri_session(action, text)
            require 'shellwords'
            require 'base64'
            require 'open3'
            

            hsm_usertype  = self.option :hsm_usertype
            hsm_password  = self.option :hsm_password
            hsm_library   = self.option :hsm_library
            hsm_slot_id   = self.option :hsm_slot_id
            key_label     = self.option :key_label

            # This base64 encodes the value for the shell argument when its
            # passed and then decodes it once the code is evaluated
            encoded_text = Base64.encode64(text).strip.tr("\r", "").tr("\n", "")

            command = "/opt/puppet/bin/eyaml"                        
            args = ["decrypt",
            "-s 'ENC[PKCS11,#{encoded_text}]'",
            "--encrypt-method pkcs11",
            "--pkcs11-mode pkcs11",
            "--pkcs11-key-label '#{key_label}'",
            "--pkcs11-hsm-password '#{hsm_password}'",
            "--pkcs11-hsm-usertype '#{hsm_usertype}'",
            "--pkcs11-hsm-library '#{hsm_library}'",
            "--pkcs11-hsm-slot-id #{hsm_slot_id}",
            "-q"
            ]

            string_command = [command].concat(args)
            full_command = string_command.join(" ")
            
            tries = 0
            begin
              captured_stdout = ''
              captured_stderr = ''
              exit_status = Open3.popen3(ENV, full_command) {|stdin, stdout, stderr, wait_thr|
                pid = wait_thr.pid # pid of the started process.
                stdin.close
                captured_stdout = stdout.read
                captured_stderr = stderr.read
                wait_thr.value # Process::Status object returned.
              }

              std_error = captured_stderr

              unless exit_status.success?
                raise "Failed"
              end
            rescue
              tries += 1
              sleep(10 * tries)
              if tries < 3
                retry
              else
                raise "Decrypt Error #{std_error}"
              end
            else
              output = captured_stdout
            end
          end

          def self.openssl(action,text)

            # This mode allows offline encyption simply using the openssl gem
            # and a RSA public key. This method will not work master side in PE 3.4
            # likely (see notes in self.session) however it will work on desktops
            # Such as Mac OS X , to allow users to encrypt values.

            require 'openssl'
            public_key_path = self.option :public_key
            public_key      = File.open(public_key_path,"rb").read
            rsa = OpenSSL::PKey::RSA.new(public_key)

            if action == :encrypt
              result = rsa.public_encrypt(text)
            elsif action == :decrypt
             raise "Decryption is not supported using openssl as you don't have access to the hsm"
            end
            result
          end
        end
      end
    end
  end
end
