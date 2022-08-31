INSERT INTO data.users (auth0_id, user_name) VALUES
('EAC742825A9C864A1FD3C43AF32DC', 'BC Ministry of Transportation and Infrastructure'), -- 1
('B46ABDABF476EFF1D81AC47D52524', 'City of Merritt'),                                  -- 2
('1B59418122BE218AA4E4D7A6E518E', 'City of Abbotsford'),                               -- 3
('F614FADE3125B3DB156EFDC8448D5', 'Trans Mountain Corporation');                        --4


INSERT INTO data.parents (parent_name, user_id, risk_level_threshold) VALUES
('Highway 5', 1, 1),          -- BC MOTI:                   1
('Infrastructures', 2, 1),    -- City of Merritt:           2
('Infrastructures', 3, 1),    -- City of Abbotsford:        3
('Pipelines Cluster 1', 4, 3); --Trans Mountain Corporation 4