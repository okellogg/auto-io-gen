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
package body SAL.Gen_Math.Gen_DOF_3.Gen_Image is

   function Image (Item : in Unit_Vector_Type) return String
   is begin
      return Image (Cart_Vector_Type'(Item (X), Item (Y), Item (Z)));
   end Image;

   function Image (Item : in Unit_Quaternion_Type) return String
   is begin
      return "(" &
        Real_Type'Image (Item.X) &
        ", " &
        Real_Type'Image (Item.Y) &
        ", " &
        Real_Type'Image (Item.Z) &
        ", " &
        Real_Type'Image (Item.S) &
        ")";
   end Image;

end SAL.Gen_Math.Gen_DOF_3.Gen_Image;

