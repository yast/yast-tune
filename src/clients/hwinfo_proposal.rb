# encoding: utf-8

# File:		proposal_hwinfo.ycp
#
# Module:		Initial hwinfo
#
# $Id$
#
# Author:		Ladislav Slezak <lslezak@suse.cz>
#
# Purpose:		Proposal function dispatcher for initial hwinfo module.
module Yast
  class HwinfoProposalClient < Client
    def main
      textdomain "tune"

      Yast.import "InitHWinfo"

      @func = Convert.to_string(WFM.Args(0))
      @param = Convert.to_map(WFM.Args(1))
      @ret = {}

      # make proposal
      if @func == "MakeProposal"
        @force_reset = Ops.get_boolean(@param, "force_reset", false)
        @ret = { "raw_proposal" => InitHWinfo.MakeProposal(@force_reset) }
      # start configuration workflow
      elsif @func == "AskUser"
        @has_next = Ops.get_boolean(@param, "has_next", false)

        # start inst_hwinfo module - start configuration workflow
        @result = Convert.to_symbol(WFM.CallFunction("inst_hwinfo", []))

        # TODO: change result to `back when no change was done?
        #       this should prevent refreshing proposal
        # Fill return map
        @ret = { "workflow_sequence" => @result }
      # return proposal description
      elsif @func == "Description"
        # Fill return map.
        @ret = {
          # this is a heading
          "rich_text_title" => _("System"),
          # this is a menu entry
          "menu_title"      => _("S&ystem"),
          "id"              => "init_hwinfo"
        }
      # write settings
      elsif @func == "Write"
        # Fill return map.
        @ret = { "success" => true }
      end

      # return result
      deep_copy(@ret)
    end
  end
end

Yast::HwinfoProposalClient.new.main
