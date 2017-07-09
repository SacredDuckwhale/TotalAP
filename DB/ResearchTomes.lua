  ----------------------------------------------------------------------------------------------------------------------
    -- This program is free software: you can redistribute it and/or modify
    -- it under the terms of the GNU General Public License as published by
    -- the Free Software Foundation, either version 3 of the License, or
    -- (at your option) any later version.
	
    -- This program is distributed in the hope that it will be useful,
    -- but WITHOUT ANY WARRANTY; without even the implied warranty of
    -- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    -- GNU General Public License for more details.

    -- You should have received a copy of the GNU General Public License
    -- along with this program.  If not, see <http://www.gnu.org/licenses/>.
----------------------------------------------------------------------------------------------------------------------


local addonName, TotalAP = ...
if not TotalAP then return end


local researchTomes = {

	139390,  -- Artifact Research Notes (max. AK 25) TODO: obsolete? Seem to be replaced by the AK 50 version entirely
	146745,  -- Artifact Research Notes (max. AK 50)
	147860,  -- Empowered Elven Tome (7.2)
	144433,  -- Artifact Research Compendium: Volume I
	144434,  -- Artifact Research Compendium: Volumes I & II
	144431,  -- Artifact Research Compendium: Volumes I-III
	144395,  -- Artifact Research Synopsis
	147852,  -- Artifact Research Compendium: Volumes I-V
	147856,  -- Artifact Research Compendium: Volumes I-IX
	147855,  -- Artifact Research Compendium: Volumes I-VIII
	144435,  -- Artifact Research Compendium: Volumes I-IV
	147853,  -- Artifact Research Compendium: Volumes I-VI
	147854,  -- Artifact Research Compendium: Volumes I-VII
	141335,  -- Lost Research Notes (TODO: Is this even ingame? -> Part of the obsolete Mage quest "Hidden History", perhaps?)

}

TotalAP.DB.ResearchTomes = researchTomes


return TotalAP.DB.ResearchTomes