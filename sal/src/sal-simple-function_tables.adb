--  Abstract:
--
--  see spec
--
--  Copyright (C) 2005 Stephen Leake.  All Rights Reserved.
--
--  This library is free software; you can redistribute it and/or
--  modify it under terms of the GNU General Public License as
--  published by the Free Software Foundation; either version 2, or (at
--  your option) any later version. This library is distributed in the
--  hope that it will be useful, but WITHOUT ANY WARRANTY; without even
--  the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
--  PURPOSE. See the GNU General Public License for more details. You
--  should have received a copy of the GNU General Public License
--  distributed with this program; see file COPYING. If not, write to
--  the Free Software Foundation, 59 Temple Place - Suite 330, Boston,
--  MA 02111-1307, USA.
--
--  As a special exception, if other files instantiate generics from
--  this unit, or you link this unit with other files to produce an
--  executable, this  unit  does not  by itself cause  the resulting
--  executable to be covered by the GNU General Public License. This
--  exception does not however invalidate any other reasons why the
--  executable file  might be covered by the  GNU Public License.

pragma License (Modified_GPL);

package body SAL.Simple.Function_Tables is

   procedure Initialize (Function_Table : in out Function_Table_Type)
   is
      Table : Table_Type renames Function_Table.Table.all;
   begin
      Function_Table.Domain_Max := Domain_Type'First;
      Function_Table.Domain_Min := Domain_Type'Last;

      --  search for max, min
      for I in Table'Range loop
         if I > Table'First and then
            Table (I).Domain_Value <= Table (I - 1).Domain_Value
         then
            raise Initialization_Error;
         end if;

         if Table (I).Domain_Value > Function_Table.Domain_Max then
            Function_Table.Domain_Max := Table (I).Domain_Value;
         end if;
         if Table (I).Domain_Value < Function_Table.Domain_Min then
            Function_Table.Domain_Min := Table (I).Domain_Value;
         end if;
      end loop;
   end Initialize;

end SAL.Simple.Function_Tables;