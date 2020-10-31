local this = {
	min_value = 3,
	max_value = 12,
	step_value = 0.5,

	menu_id = "menu_despawn_shield_id",
	slider_id = "menu_despawn_shield_slider_id",
	slider_desc = "menu_despawn_shield_slider_desc",
	timer_id = "menu_despawn_shield_format_id"
}

if not ShieldDespawnTimer then
	ShieldDespawnTimer = ShieldDespawnTimer or {}
	ShieldDespawnTimer.config_path = SavePath .. "despawn_timer.txt"

	function ShieldDespawnTimer:save()
		local f = io.open( self.config_path, "w+" )
		if type( f ) == "userdata" then
			f:write( Application:digest_value( self.timer, true ) )
			f:close()
		end
	end

	function ShieldDespawnTimer:load()
		local f = io.open( self.config_path, "r" )
		if type( f ) == "userdata" then
			self.timer = Application:digest_value( f:read( "*a" ), false )
			f:close()
		end
	end

	function ShieldDespawnTimer:get_time( skip_time )
		local valid = type( self.timer ) == "number" and self.timer >= this.min_value and self.timer <= this.max_value
		self.timer = valid and self.timer or this.min_value

		return ( skip_time and 0 or Application:time() ) + self.timer
	end

	function ShieldDespawnTimer:setup_hooks()
		if not self._loaded then
			self._loaded = true
			self:load()
		end

		if RequiredScript == "lib/units/enemies/cop/copinventory" then
			Hooks:PostHook( CopInventory, "drop_shield", "ShieldDespawnTimer", function( u )
				if alive( u._shield_unit ) then
					local function clbk_hide()
						if alive( u._shield_unit ) then
							managers.enemy:unregister_shield( u._shield_unit )
							u._shield_unit:set_slot( 0 )
							u._shield_unit = nil
						end
					end

					managers.enemy:add_delayed_clbk( "", clbk_hide, self:get_time() )
				end
			end)
		else
			Hooks:Add( "LocalizationManagerPostInit", "Localization_ShieldDespawnTimer", function( self )
				self:add_localized_strings(
					{
						[this.menu_id] = "Shield Despawn Timer",
						[this.slider_desc] = "Set shield despawn timer.\n12 seconds is the in-game default.",
						[this.slider_id] = "Despawn timer",
						[this.timer_id] = "%.1f SEC."
					}
				)
			end)

			Hooks:Add( "MenuManagerSetupCustomMenus", "Setup_ShieldDespawnTimer", function()
				MenuHelper:NewMenu( this.menu_id )
				MenuCallbackHandler[this.menu_id] = function( _, item )
					if item and item:name() == this.slider_id then
						local value = item:value()
						self.timer = value - value % this.step_value
						item:set_value( self.timer )
					else
						self:save()
					end
				end
			end)

			Hooks:Add( "MenuManagerPopulateCustomMenus", "Populate_ShieldDespawnTimer", function()
				MenuHelper:AddSlider(
					{
						id = this.slider_id,
						title = this.slider_id,
						desc = this.slider_desc,
						value = self:get_time( true ),
						callback = this.menu_id,
						menu_id = this.menu_id,
						step = this.step_value,
						min = this.min_value,
						max = this.max_value
					}
				)
			end)

			Hooks:Add( "MenuManagerBuildCustomMenus", "Menu_ShieldDespawnTimer", function( _, nodes )
				nodes[this.menu_id] = MenuHelper:BuildMenu( this.menu_id, { back_callback = this.menu_id } )
				MenuHelper:AddMenuItem( nodes.blt_options, this.menu_id, this.menu_id )

				for k, v in ipairs( nodes[this.menu_id]._items ) do
					if v._type == "slider" then
						v.reload = function( self, item )
							local p = self:percentage() / 100
							item = item or v._parameters.gui_node.row_items[k]
							item.gui_slider_text:set_text( managers.localization:text( this.timer_id ):format( self:value() ) )
							item.gui_slider_marker:set_center_x( item.gui_slider:left() + item.gui_slider:w() * p )
							item.gui_slider_gfx:set_w( item.gui_slider:w() * p )
							return true
						end
					end
				end
			end)
		end
	end
end

ShieldDespawnTimer:setup_hooks()