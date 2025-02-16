def master_slave_group(groups):
    return 'master' if 'master' in groups else 'slave' if 'slave' in groups else 'proxy' 

class FilterModule(object):
    def filters(self):
        return {
            'master_slave_group': master_slave_group,
        }