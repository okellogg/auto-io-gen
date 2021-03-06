--  Abstract :
--
--  see spec.
--
--  Copyright (C) 2001 - 2005 Stephen Leake.  All Rights Reserved.
--
--  This program is free software; you can redistribute it and/or
--  modify it under terms of the GNU General Public License as
--  published by the Free Software Foundation; either version 2, or
--  (at your option) any later version. This program is distributed in
--  the hope that it will be useful, but WITHOUT ANY WARRANTY; without
--  even the implied warranty of MERCHANTABILITY or FITNESS FOR A
--  PARTICULAR PURPOSE. See the GNU General Public License for more
--  details. You should have received a copy of the GNU General Public
--  License distributed with this program; see file COPYING. If not,
--  write to the Free Software Foundation, 59 Temple Place - Suite
--  330, Boston, MA 02111-1307, USA.
--
--  Design:
--
--  Array and scalar types are all handled in the Text_IO package
--  spec, by instantiating appropriate Text_IO packages.
--
--  For record types, there are five cases:
--
--  1) Non-variant, public record types with no discriminants. We just
--     do a sequence of Get's on each component, directly into the Item
--     parameter.
--
--  2) Variant records: not supported (yet; too complicated, normally
--     superceded by tagged types anyway).
--
--  3) Record types declared in the private part: generate
--     Private_Text_IO child package.
--
--  4) Record types with discriminants, with defaults. Here we call
--     these "Constrained_Discriminants". Since the Item parameter is
--     constrained, we can just compare the discriminants read from the
--     file with the constraints, and raise Discriminant_Error for a
--     mis-match. The other components are then read directly into Item.
--
--     An alternative is to pass an access type as Item, and allocate a
--     new constrained object. This is not supported (yet; would
--     require user annotation).
--
--  5) Record types with discriminants, with no defaults. Here we call
--     these "Unconstrained_Discriminants". The discriminants are read
--     into local scalar temporary variables. Then a local temporary
--     object is declared with those discriminants, the other components
--     are read into that temp, and finally the temp is assigned to Item.
--

with Ada.Exceptions;
with Ada.IO_Exceptions;
with Ada.Strings.Fixed;
with Asis.Aux;
with Asis.Elements;
with Auto_Io_Gen.Generate.Ada_Image.Put_Body;
with Auto_Io_Gen.Generate.Ada_Image.Spec;
with Auto_Io_Gen.Options;
with SAL.Gen.Alg.Process_All_Constant;
with GNAT.Source_Info;
package body Auto_Io_Gen.Generate.Ada_Image is
   use GNAT.Source_Info;
   --------------
   --  Local declarations

   procedure Create_File
     (File : in out Ada.Text_IO.File_Type;
      Name : in     String)
     --  Create File with Name, deleting an existing one if necessary
     --  and permitted by Options.
   is
      use Ada.Text_IO;
   begin
      if Options.Verbose then
         Put_Line ("Creating " & Name);
      end if;

      Create (File, Out_File, Name);

   exception
      when Ada.IO_Exceptions.Use_Error =>
         if Options.Overwrite_Child then
            --  See if it currently exists and we can delete it.
            begin
               Open (File, Out_File, Name);
            exception
               when Ada.IO_Exceptions.Use_Error =>
                  Ada.Exceptions.Raise_Exception
                    (Parameter_Error'Identity,
                     "cannot create Images child " & Name & ". Possibly it exists but is read-only");
            end;
            Delete (File);
            begin
               Create (File, Out_File, Name);
            exception
               when others =>
                  Ada.Exceptions.Raise_Exception
                    (Parameter_Error'Identity,
                     "cannot create Images child " & Name);
            end;
         else
            Ada.Exceptions.Raise_Exception
              (Parameter_Error'Identity,
               "Images child " & Name & " already exists. Use -f to overwrite it.");
         end if;

      when Ada.IO_Exceptions.Name_Error =>
         Ada.Exceptions.Raise_Exception
           (Parameter_Error'Identity,
            "'" & Name & "' is not a valid file name");
   end Create_File;

   procedure Generate_Child_Body
     (File                : in Ada.Text_IO.File_Type;
      Type_List           : in Auto_Io_Gen.Lists.Type_Descriptor_Lists.List_Type;
      With_List           : in Auto_Io_Gen.Lists.Context_Trees.Tree_Type;
      Parent_Package_Name : in String;
      Child_Package_Name  : in String;
      Invisible           : in Boolean;
      Needs_Text_IO_Utils : in Boolean)
   is
      pragma Unreferenced (Needs_Text_IO_Utils);
      use Ada.Text_IO;

      procedure Print_Header (Type_List : in Auto_Io_Gen.Lists.Type_Descriptor_Lists.List_Type)
      is
         pragma Unreferenced (Type_List);
         use Auto_Io_Gen.Lists.Context_Trees_Iterators;
         Iterator             : Iterator_Type := First (With_List);
      begin
         Put_Line (File, "--  Abstract :");
         Put_Line (File, "--");
         Put_Line (File, "--  See spec. This file is auto-generated by " & Auto_Io_Gen.Program_Name);
         Put_Line (File, "--  from " & Parent_Package_Name);
         Put_Line (File, "--");
         Put_Line (File, "with Auto_Image;  use Auto_Image;");

         loop
            exit when Is_Null (Iterator);

            if Current (Iterator).Need_Use then
               Put_Line (File, "with " & Current (Iterator).Name.all & "; use " &
                           Current (Iterator).Name.all & ";");

            else
               Put_Line (File, "with " & Current (Iterator).Name.all & ";");
            end if;

            Next (Iterator);
         end loop;


         Put_Line (File, "package body " & Child_Package_Name & " is");
         Put_Line (File, "   pragma Warnings(off);");

         New_Line (File);
         Indent_Level := 2;
         Set_Indent (File);

      end Print_Header;

      procedure Print_Type
        (Type_Descriptor : in Auto_Io_Gen.Lists.Type_Descriptor_Access_Type;
         First           : in Boolean                                       := True)
      is
         pragma Unreferenced (First);
         use type Lists.Type_Labels_Type;
      begin
         if (Invisible and not Type_Descriptor.Invisible) or
           (not Invisible and Type_Descriptor.Invisible)
         then
            --  This type belongs in the other Text_IO child
            --  (invisible types in private child).
            return;
         end if;

         if Type_Descriptor.Label = Lists.Access_Label then
            declare
               Base_Name : constant String := Asis.Aux.Name (Type_Descriptor.Accessed_Subtype_Ident);
               Type_Name : constant String := Asis.Aux.Name (Type_Descriptor.Type_Name);
            begin
               Indent_Line (File, "package " & Type_Name & "_Aux is new Auto_Text_Io.Access_IO.Conversions",
                                  "            (" & Base_Name & ", " & Type_Name & ");");
               New_Line (File);
            end;
         end if;

         Put_Body.Generate (File, Type_Descriptor.all);
      end Print_Type;

      procedure Print_Footer (Type_List : in Auto_Io_Gen.Lists.Type_Descriptor_Lists.List_Type)
      is
         pragma Unreferenced (Type_List);
      begin
         Put_Line (File, "end " & Child_Package_Name & ";");
      end Print_Footer;

      procedure Print_Type_List is new Auto_Io_Gen.Lists.Type_Descriptor_Algs.Process_All_Constant
        (Pre_Process_Container  => Print_Header,
         Process_Item           => Print_Type,
         Post_Process_Container => Print_Footer);

   begin
      Print_Type_List (Type_List);
   end Generate_Child_Body;

   --------------
   --  Public operations

   procedure Create_Text_IO_Child
     (Type_List           : in Lists.Type_Descriptor_Lists.List_Type;
      Spec_With_List      : in Lists.Context_Trees.Tree_Type;
      Body_With_List      : in Lists.Context_Trees.Tree_Type;
      Formal_Package_List : in Lists.Formal_Package_Lists.List_Type;
      Parent_Package_Name : in String;
      Needs_Body          : in Boolean;
      Needs_Text_IO_Utils : in Boolean;
      Invisible           : in Boolean;
      Is_Generic          : in Boolean)
   is
      use Ada.Text_IO;
      use Auto_Io_Gen.Options;


      Child_Spec_File : File_Type; --  The output .Text_IO spec
      Child_Body_File : File_Type; --  The output .Text_IO body

      Child_Package_Name : constant String := Parent_Package_Name & Options.Package_Separator &
      (if Is_Generic then "Gen_" else "" ) &
      (if Invisible then "Private_" else "" ) & "Images";

   begin

      if Options.Debug then
         Put_Line (Enclosing_Entity & "(" & Parent_Package_Name &
                   (if Needs_Body then ",Needs_Body" else "" ) &
                   (if Needs_Text_IO_Utils then ",Needs_Body" else "" ) &
                   (if Needs_Text_IO_Utils then ",Needs_Text_IO_Utils" else "" ) &
                   (if Invisible then ",Invisible" else "" ) &
                   (if Is_Generic then ",Is_Generic" else "" ) & ")");
      end if;

      Create_File (Child_Spec_File, Ada2file  (Options.Destination_Dir.all, Child_Package_Name, Options.Spec_File_Extension));

      Spec.Generate_Child_Spec
        (Child_Spec_File,
         Type_List           => Type_List,
         With_List           => Spec_With_List,
         Formal_Package_List => Formal_Package_List,
         Parent_Package_Name => Parent_Package_Name,
         Child_Package_Name  => Child_Package_Name,
         Invisible           => Invisible,
         Is_Generic          => Is_Generic);

      Close (Child_Spec_File);

      if Needs_Body then
         Create_File (Child_Body_File, Ada2file  (Options.Destination_Dir.all, Child_Package_Name, Options.Body_File_Extension));

         Generate_Child_Body
           (Child_Body_File,
            Type_List,
            Body_With_List,
            Parent_Package_Name => Parent_Package_Name,
            Child_Package_Name  => Child_Package_Name,
            Invisible           => Invisible,
            Needs_Text_IO_Utils => Needs_Text_IO_Utils);

         Close (Child_Body_File);
      end if;

   exception
      when others =>
         --  If there were no errors, these files would not still be open.
         --  So delete them.
         if Is_Open (Child_Spec_File) then
            Delete (Child_Spec_File);
         end if;

         if Is_Open (Child_Body_File) then
            Delete (Child_Body_File);
         end if;

         raise;
   end Create_Text_IO_Child;

   -----------
   --  Operations for child packages


   function Component_Type_Name
     (Type_Element         : in Asis.Element;
      Type_Package_Element : in Asis.Element)
      return String
   is
      use Asis;
   begin
      if Elements.Is_Nil (Type_Package_Element) then
         return Aux.Name (Type_Element);
      else
         return Aux.Name (Type_Package_Element) & "." & Aux.Name (Type_Element);
      end if;
   end Component_Type_Name;

   function Instantiated_Package_Name (Type_Name : in String) return String
   is
      Root_Name_Index : Natural := Ada.Strings.Fixed.Index (Type_Name, "_Type");
   begin
      if Root_Name_Index = 0 then
         --  Name does not end in "_Type", so use all of it.
         Root_Name_Index := Type_Name'Last;
      else
         --  Point Root_Index to just before "_Type"
         Root_Name_Index := Root_Name_Index - 1;
      end if;

      return Type_Name (Type_Name'First .. Root_Name_Index) & "_Images";

   end Instantiated_Package_Name;

   procedure Instantiate_Generic_Array_Text_IO
     (File            : in Ada.Text_IO.File_Type;
      Type_Descriptor : in Lists.Type_Descriptor_Type)
   is
      use Ada.Text_IO;

      function Select_Generic (Label : in Lists.Array_Component_Labels_Type) return String
      is begin
         case Label is
         when Lists.Private_Label =>
            return "Private_1D";
         when Lists.Enumeration_Label =>
            return "Enumeration_1D";
         when Lists.Float_Label =>
            return "Float_1D";
         when Lists.Signed_Integer_Label =>
            return "Integer_1D";
         when Lists.Modular_Integer_Label =>
            return "Modular_1D";
         end case;
      end Select_Generic;

      Generic_Name : constant String := Select_Generic (Type_Descriptor.Array_Component_Label);
      Type_Name    : constant String := Asis.Aux.Name (Type_Descriptor.Type_Name);
      Package_Name : constant String := Instantiated_Package_Name (Type_Name);
   begin
      Indent (File, "package " & Package_Name & " is new Auto_Image.Gen_Array_Image_IO.");

      case Lists.Array_Labels_Type'(Type_Descriptor.Label) is
      when Lists.Constrained_Array_Label =>
         Put (File, Generic_Name);

      when Lists.Unconstrained_Array_Label =>
         Put (File, "Unconstrained_" & Generic_Name);

      end case;

      Indent_Level := Indent_Level + 1;

      Indent_Line
        (File,
         "(Element_Type             => " &
           Component_Type_Name
           (Type_Descriptor.Array_Component_Subtype,
            Type_Descriptor.Array_Component_Subtype_Package) &
           ",");

      Indent_Line
        (File,
         " Index_Type               => " &
           Component_Type_Name (Type_Descriptor.Array_Index, Type_Descriptor.Array_Index_Package) &  ",");

      Indent_Line (File, " Index_Array_Element_Type => " & Type_Name & ",");

      if Asis.Elements.Is_Nil (Type_Descriptor.Array_Component_Type_Package) then
         Indent
           (File,
            " Element_Put              => ");
      else
         Indent
           (File,
            " Element_Put              => " &
              Text_IO_Child_Name (Type_Descriptor.Array_Component_Type_Package) & ".");
      end if;

      Put_Line (File, "Put);");
      New_Line (File);

      Indent_Level := Indent_Level - 1;

   end Instantiate_Generic_Array_Text_IO;

   function Root_Type_Name (Type_Name : in String) return String
   is
      Root_Name_Index : Natural := Ada.Strings.Fixed.Index (Type_Name, "_Type");
   begin
      if Root_Name_Index = 0 then
         --  Name does not end in "_Type", so use all of it.
         Root_Name_Index := Type_Name'Last;
      else
         --  Point Root_Index to just before "_Type"
         Root_Name_Index := Root_Name_Index - 1;
      end if;

      return Type_Name (Type_Name'First .. Root_Name_Index);

   end Root_Type_Name;

   function Standard_Name (Type_Name : in String) return String
   is
      pragma Unreferenced (Type_Name);
   begin
      return "Auto_Image.Standard";
   end Standard_Name;

begin
   Auto_Io_Gen.Options.Register
     (Option => "images", Language_Name => "Images",
      Generator => Create_Text_IO_Child'Access,
      Std_Names =>  Standard_Name'Access);

end Auto_Io_Gen.Generate.Ada_Image;
