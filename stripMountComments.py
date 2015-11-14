
'''
run to generate a stripped mount to save nvram space
'''

import re

def minify(inPath,outPath):
	with open(inPath,'r') as inSr, open(outPath,'wb') as outSr:
		for line in inSr.readlines():
			line=line.rstrip('\r\n')
			line=re.sub(r'\s*#.+$','',line)
			#convert leading tabs to spaces
			lineStripped=line.lstrip()
			line=' '*(len(line)-len(lineStripped))+lineStripped
			if not line:
				continue
			outSr.write(line.encode()+b'\n')
		outSr.seek(-1,1)
		outSr.truncate()
	
def echoEscape(inPath,outPath):
	with open(inPath,'rb') as inSr, open(outPath,'wb') as outSr:
		#use strong quoting in sh
		outSr.write(b'\'')
		outSr.write(re.sub(br'([\'])',b'\'"\\1"\'',inSr.read()))
		outSr.write(b'\'')

def main():
	inPath='mount.sh'
	minPath='mount_.sh'
	echoPath='mount_echo.sh'
	minify(inPath,minPath)
	echoEscape(minPath,echoPath)	
	
	
if __name__=='__main__':
	main()
