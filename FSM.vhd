
   
   

  

    -- data_to_fcs <= s_data_to_fcs; 

    sof <= s_start_of_frame;
    -- data_to_fcs <= s_data_to_fcs;

        PROCESS (clk, rst)
        BEGIN

            IF rst = '1' THEN

                state(ii) <= state_idle;
                preamble_cnt(ii) <= 0;
                data_cnt(ii) <= 0;
                mac_addr_cnt(ii) <= 0;
                ethertype_cnt(ii) <= 0;

            ELSIF rising_edge(clk) THEN
                -- data_to_fcs <= (OTHERS => '0');
                s_start_of_frame(ii) <= '0';
                CASE state(ii) IS
                    WHEN state_idle =>
                        s_start_of_frame(ii) <= '0';
                        s_data_to_fcs(ii) <= (OTHERS => '0');
                        preamble_cnt(ii) <= 0;
                        data_cnt(ii) <= 0;
                        mac_addr_cnt(ii) <= 0;
                        ethertype_cnt(ii) <= 0;

                        IF data_valid = '1' THEN
                            IF data_in = x"AA" THEN
                                preamble_cnt(ii) <= preamble_cnt(ii) + 1;
                            END IF;
                            state(ii) <= state_preamble;

                        END IF;

                    WHEN state_preamble =>

                        IF data_in = x"AA" AND data_valid = '1' THEN
                            preamble_cnt(ii) <= preamble_cnt(ii) + 1;
                        END IF;

                        IF preamble_cnt(ii) = 7 AND data_in = x"AB" THEN
                            state(ii) <= state_data;
                            s_start_of_frame(ii) <= '1';
                        ELSIF data_valid = '0' THEN
                            state(ii) <= state_idle;
                        END IF;

                        -- WHEN state_SOF =>
                        --     IF data_in = x"AB" AND data_valid = '1' THEN
                        --         state(ii) <= state_data;
                        --     ELSIF data_valid = '0' THEN
                        --         state(ii) <= state_idle;
                        --     END IF;

                    WHEN state_data =>
                        IF state(ii) = state_data AND data_valid = '1' THEN
                            fcs_data_valid <= '1';
                        ELSE
                            fcs_data_valid <= '0';
                        END IF;
                        --       fcs_data_valid <= '1' WHEN state(ii) = state_data AND data_valid = '1' ELSE '0';
                        data_to_fcs <= data_in; -- Hooking up the internal signal to the output
                        s_data_to_fcs <= data_in;
                        data_cnt(ii) <= data_cnt(ii) + 1;

                        -- a little weird. they should all be 1's in here
                        IF data_valid = '1' THEN
                            s_data_to_switch_core_fifo <= '1' & data_in;
                        ELSE
                            s_data_to_switch_core_fifo <= '0' & data_in;
                        END IF;

                        IF data_cnt(ii) < 13 THEN
                            s_data_to_mac_fifo <= data_in;
                            -- mac addr_cnt <= mac_addr_cnt + 1;

                        ELSIF data_cnt(ii) < 15 THEN
                            s_data_to_ethertype <= data_in;
                            -- ethertype_cnt <= ethertype_cnt + 1;

                        ELSIF data_valid = '0' THEN
                            state(ii) <= state_idle;
                        END IF;

                END CASE;
            END IF;

        END PROCESS;
  END GENERATE fcs_generate;