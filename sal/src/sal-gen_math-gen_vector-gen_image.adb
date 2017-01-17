--  Abstract :
--
--  See spec.
--
--  Copyright (C) 2002 Stephen Leake.  All Rights Reserved.
--
--  SAL is free software; you can redistribute it and/or modify it
--  under terms of the GNU General Public License as published by the
--  Free Software Foundation; either version 2, or (at your option) any
--  later version. SAL is distributed in the hope that it will be
--  useful, but WITHOUT ANY WARRANTY; without even the implied warranty
--  of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
--  General Public License for more details. You should have received a
--  copy of the GNU General Public License distributed with SAL; see
--  file COPYING. If not, write to the Free Software Foundation, 59
--  Temple Place - Suite 330, Boston, MA 02111-1307, USA.
--
--  As a special exception, if other files instantiate generics from
--  SAL, or you link SAL object files with other files to produce
--  an executable, that does not by itself cause the resulting
--  executable to be covered by the GNU General Public License. This
--  exception does not however invalidate any other reasons why the
--  executable file might be covered by the GNU Public License.
--
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
function SAL.Gen_Math.Gen_Vector.Gen_Image  (Item : in Index_Array_Real_Type) return String
is
   use Ada.Strings.Unbounded;
   Result : Unbounded_String := To_Unbounded_String ("(");
begin
   for I in Item'Range loop
      Append (Result, Real_Type'Image (Item (I)));
      if I /= Item'Last then
         Append (Result, ", ");
      end if;
   end loop;
   Append (Result, ")");
   return To_String (Result);
end SAL.Gen_Math.Gen_Vector.Gen_Image;

