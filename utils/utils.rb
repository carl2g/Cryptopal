#!/usr/bin/ruby
# @Author: carl
# @Date:   2018-07-08 13:05:10
# @Last Modified by:   carl
# @Last Modified time: 2018-07-29 22:19:40

FR_FREQ = {
	'e' => 0.1210, 'a' => 0.0711, 'i' => 0.0659, 's' => 0.0651,
	'n' => 0.0639, 'r' => 0.0607, 't' => 0.0592, 'o' => 0.0502,
	'l' => 0.0496, 'u' => 0.0449, 'd' => 0.0367, 'c' => 0.0318,
	'm' => 0.0262, 'p' => 0.0249, 'é' => 0.0194, ' ' => 0.0156
}

def get_key_size(bin_str, real_freq, nb = 10)
	real_freq = real_freq.sort_by { |k, v| v }.last(nb).to_h
	real_keys = real_freq.keys
	delt = {}
	# (1..40).each do |keysize|
	(1..3).each do |keysize|
		seg_bin = {}
		tmp = 0.0
		puts "key size: #{keysize}"
		bin_str.scan(/.{#{keysize * 8}}/).each_with_index do |byte, i|
			if seg_bin[(i % keysize) + 1]
				seg_bin[(i % keysize) + 1] += byte
			else
				seg_bin.store((i % keysize) + 1, byte)
			end
		end
		seg_bin.each do |key, bin|
			data_freq = get_data_freq(bin, nb)
			puts data_freq
			puts real_freq
			data_keys = data_freq.keys
			(0...data_freq.size).each do |i|
				tmp += (real_freq[real_keys[i]] - data_freq[data_keys[i]]).abs
			end
		end
		puts
		# tmp = (tmp / keysize.to_f).round(4)
		delt[keysize] = tmp
	end
	return delt.sort_by { |k, v| v }.to_h
end

def conv_dec_bin(nb, res = '0' * 64)
	return res if nb <= 0
	i = 1
	tmp = 1
	while nb / i > 1
		tmp += 1
		i = i * 2
	end
	res[res.length - tmp] = "1"
	res = conv_dec_bin(nb - i, res)
end

def conv_base_bin(str, base)
	res = ""
	len = calc_byte_base(base)
	str.split('').each do |elem|
		break if elem == "="
		res += conv_dec_bin(find_pos(elem, base), "0" * len)
	end
	return res
end

def conv_bin_dec(bin, res = 0)
	i = 1
	bin.reverse.split('').each do |bite|
		res += bite.to_i * i
		i = i * 2
	end
	return res
end

def conv_bin_str(bin)
	res = ""
	bin.scan(/.{8}/).each do |byte|
		res += conv_bin_dec(byte).chr
	end
	return res
end

def calc_byte_base(base)
	len = 0
	base_len = base.length
	while (base_len > 1)
		base_len = base_len / 2;
		len += 1
	end
	return len
end

def conv_bin_base(bin, base)
	len = calc_byte_base(base)
	i = 0
	res = ""
	while (i < bin.length)
		pos = conv_bin_dec(bin[i...i + len], 0)
		res += find_elem_at_pos(pos, base)
		i += len
	end
	return res
end

def find_elem_at_pos(pos, base)
	base[pos]
end

def find_pos(c, base)
	base.index(c);
end

def get_xor_key(dec, res, len = 8)
	bin = conv_dec_bin(dec, "0" * len)
	bin_res = conv_dec_bin(res, "0" * len)
	res = "0" * len
	bin.split('').each_with_index do |bite, i|
		res[i] = (bin_res[i].to_i ^ bin[i].to_i).to_s
	end
	return res
end

def conv_str_to_bin(str)
	res = ""
	str.split('').each do |c|
		res += conv_dec_bin(c.ord, '0' * 8)
	end
	return res
end

def xor(str1, str2)
	res = ""
	str1.split('').each_with_index do |elem, i|
		res += (str1[i].to_i ^ str2[i].to_i).to_s
	end
	return res
end

def get_freq_char(str, nb = 5)
	freq = {}
	str.split('').each do |c|
		if freq[c]
			freq[c] += 1
		else
			freq.store(c, 1)
		end
	end
	freq.each { |k, v| freq[k] = (v.to_f / str.size).round(4) }
	freq.sort_by { |k, v| v }.last(nb).to_h
end

def calc_hamming_dist(bin1, bin2)
	res = xor(bin1, bin2)
	nb = 0
	res.split('').each do |bite|
		nb += 1 if bite == '1'
	end
	return nb
end

def get_data_freq(bin_str, nb = 5)
	new_str = ""
	bin_str.scan(/.{8}/).each do |oct|
		new_str += conv_bin_dec(oct).chr
	end
	# puts new_str
	freq = get_freq_char(new_str, nb)
end

def find_key_and_xor(bin_str, nb = 5)
	freq = get_data_freq(bin_str, nb)
	freq.each do |key, val|
		'etaoin shrdlu'.split('').each do |c|
			res = ""
			tmp = conv_bin_dec(get_xor_key(key.ord, c.ord, 8))
			bin_str.scan(/.{8}/).each do |oct|
				if ((conv_bin_dec(oct) ^ tmp).chr.match(/[[:print:] | [:space:]]/))
					res += (conv_bin_dec(oct) ^ tmp).chr
				else
					# puts "#{(conv_bin_dec(oct) ^ tmp).chr} == #{(conv_bin_dec(oct) ^ tmp)}"
					break
				end
			end
			# puts res
			# puts "#{res.length} == #{bin_str.length / 8}"
			puts "#{c} == #{res}" if (res.length == bin_str.length / 8)
		end
	end
end