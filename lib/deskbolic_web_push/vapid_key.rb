# frozen_string_literal: true

module DeskbolicWebPush
  # Class for abstracting the generation and encoding of elliptic curve public and private keys for use with the VAPID protocol
  #
  # @attr_reader [OpenSSL::PKey::EC] :curve the OpenSSL elliptic curve instance
  class VapidKey
    # Create a VapidKey instance from encoded elliptic curve public and private keys
    #
    # @return [DeskbolicWebPush::VapidKey] a VapidKey instance for the given public and private keys
    def self.from_keys(public_key, private_key)
      key = new
      priv_raw = DeskbolicWebPush.decode64(private_key)
      pub_raw = DeskbolicWebPush.decode64(public_key)
      asn1 = OpenSSL::ASN1::Sequence([
        OpenSSL::ASN1::Integer(1),
        OpenSSL::ASN1::OctetString(priv_raw),
        OpenSSL::ASN1::ObjectId('prime256v1', 0, :EXPLICIT),
        OpenSSL::ASN1::BitString(pub_raw, 1, :EXPLICIT)
      ])
      key.instance_variable_set(:@curve, OpenSSL::PKey::EC.new(asn1.to_der))

      key
    end

    # Create a VapidKey instance from pem encoded elliptic curve public and private keys
    #
    # @return [DeskbolicWebPush::VapidKey] a VapidKey instance for the given public and private keys
    def self.from_pem(pem)
      key = new
      src = OpenSSL::PKey.read pem
      key.curve.public_key = src.public_key
      key.curve.private_key = src.private_key

      key
    end

    attr_reader :curve

    def initialize
      @curve = if OpenSSL::PKey::EC.respond_to?(:generate)
                 OpenSSL::PKey::EC.generate('prime256v1')
               else
                 c = OpenSSL::PKey::EC.new('prime256v1')
                 c.generate_key
                 c
               end
    end

    # Retrieve the encoded elliptic curve public key for VAPID protocol
    #
    # @return [String] encoded binary representation of 65-byte VAPID public key
    def public_key
      encode64(curve.public_key.to_bn.to_s(2))
    end

    # Retrieve the encoded elliptic curve public key suitable for the Web Push request
    #
    # @return [String] the encoded VAPID public key for us in 'Encryption' header
    def public_key_for_push_header
      trim_encode64(curve.public_key.to_bn.to_s(2))
    end

    # Retrive the encoded elliptic curve private key for VAPID protocol
    #
    # @return [String] base64 urlsafe-encoded binary representation of 32-byte VAPID private key
    def private_key
      encode64(curve.private_key.to_s(2))
    end

    def public_key=(key)
      # No-op, handled in from_keys for OpenSSL 3.0 compatibility
    end

    def private_key=(key)
      # No-op, handled in from_keys for OpenSSL 3.0 compatibility
    end

    def curve_name
      group.curve_name
    end

    def group
      curve.group
    end

    def to_h
      { public_key: public_key, private_key: private_key }
    end
    alias to_hash to_h

    def to_pem
      public_key = OpenSSL::PKey::EC.new curve
      public_key.private_key = nil

      curve.to_pem + public_key.to_pem
    end

    def inspect
      "#<#{self.class}:#{object_id.to_s(16)} #{to_h.map { |k, v| ":#{k}=#{v}" }.join(' ')}>"
    end

    private

    def to_big_num(key)
      OpenSSL::BN.new(DeskbolicWebPush.decode64(key), 2)
    end

    def encode64(bin)
      DeskbolicWebPush.encode64(bin)
    end

    def trim_encode64(bin)
      encode64(bin).delete('=')
    end
  end
end
