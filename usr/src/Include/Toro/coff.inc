const
COFF_MAGIC=$14c;

COFF_TEXT=$0020;
COFF_BBS=$0080;
COFF_DATA=$0040;



Type
p_coff_header=^coff_header;
coff_header=record

 f_magic:word;	{/* magic number			*/}
 f_nscns:word;	{/* number of sections		*/}
 f_timdat:dword;	{/* time & date stamp		*/}
 f_symptr:dword;	{/* file pointer to symtab	*/	   }
 f_nsyms:dword;     {/* number of symtab entries	*/                }
 f_opthdr:word;	{/* sizeof(optional hdr)		*/}
 f_flags:word;	{/* flags			*/	   }

end;

p_coff_sections=^coff_sections;
coff_sections=record

	s_name:array[1..8] of char;	{/* section name			*/}
	s_paddr:dword;	                {/* physical address, aliased s_nlib */	   }
	s_vaddr:dword;	                {/* virtual address		*/	   }
	s_size:dword;		{/* section size			*/}
	s_scnptr:dword;	{/* file ptr to raw data for section */}
	s_relptr:dword;	{/* file ptr to relocation	*/}
	s_lnnoptr:dword;	{/* file ptr to line numbers	*/}
	s_nreloc:word;	{/* number of relocation entries	*/}
	s_nlnno:word;	{/* number of line number entries*/}
	s_flags:dword;	{/* flags			*/}
end;


Type
p_coff_opheader=^coff_optheader;
coff_optheader=record
  magic:word;          {/* type of file                         */}
  vstamp:word;         {/* version stamp                        */}
  tsize:dword;         {/* text size in bytes, padded to FW bdry*/}
  dsize:dword;         {/* initialized data    "  "             */}
  bsize:dword;         {/* uninitialized data  "  "             */}
  entry:pointer;         {/* entry pt.                            */}
  text_start:dword;    {/* base of text used for this file      */}
  data_start:dword;    {/* base of data used for this file      */}

end;


