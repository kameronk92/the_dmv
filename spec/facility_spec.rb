require 'spec_helper'

RSpec.describe Facility do
  before(:each) do
    @facility_1 = Facility.new({name: 'DMV Tremont Branch', address: '2855 Tremont Place Suite 118 Denver CO 80205', phone: '(720) 865-4600'})
    @facility_2 = Facility.new({name: 'DMV Northeast Branch', address: '4685 Peoria Street Suite 101 Denver CO 80239', phone: '(720) 865-4600'})
    @cruz = Vehicle.new({vin: '123456789abcdefgh', year: 2012, make: 'Chevrolet', model: 'Cruz', engine: :ice} )
    @bolt = Vehicle.new({vin: '987654321abcdefgh', year: 2019, make: 'Chevrolet', model: 'Bolt', engine: :ev} )
    @camaro = Vehicle.new({vin: '1a2b3c4d5e6f', year: 1969, make: 'Chevrolet', model: 'Camaro', engine: :ice} )
    @registrant_1 = Registrant.new('Bruce', 18, true )
    @registrant_2 = Registrant.new('Penny', 16 ) #was age 15 before, changed following interaction pattern
    @registrant_3 = Registrant.new('Tucker', 15 )
  end

  describe '#initialize' do
    it 'can initialize' do
      expect(@facility_1).to be_an_instance_of(Facility)
      expect(@facility_1.name).to eq('DMV Tremont Branch')
      expect(@facility_1.address).to eq('2855 Tremont Place Suite 118 Denver CO 80205')
      expect(@facility_1.phone).to eq('(720) 865-4600')
      expect(@facility_1.services).to eq([])
    end
  end

  describe '#add service' do
    it 'can add available services' do
      expect(@facility_1.services).to eq([])
      @facility_1.add_service('New Drivers License')
      @facility_1.add_service('Renew Drivers License')
      @facility_1.add_service('Vehicle Registration')
      expect(@facility_1.services).to eq(['New Drivers License', 'Renew Drivers License', 'Vehicle Registration'])
    end
  end

  describe '#register_vehicle' do
    it 'registers vehicles if capable' do
      expect(@facility_1.register_vehicle(@bolt)).to eq(nil)
      @facility_1.add_service("Vehicle Registration")
      @facility_1.register_vehicle(@cruz)
      expect(@facility_1.collected_fees).to eq(100)
      expect(@facility_1.instance_variable_get(:@registered_vehicles).length).to eq(1)
      expect(@cruz.plate_type).to eq(:regular)
      expect(@cruz.registration_date).to eq(Date.today)
      @facility_1.register_vehicle(@camaro)
      expect(@facility_1.collected_fees).to eq(125)
      expect(@facility_1.instance_variable_get(:@registered_vehicles).length).to eq(2)
      expect(@camaro.plate_type).to eq(:antique)
      expect(@camaro.registration_date).to eq(Date.today)
      @facility_1.register_vehicle(@bolt)
      expect(@facility_1.collected_fees).to eq(325)
      expect(@facility_1.instance_variable_get(:@registered_vehicles).length).to eq(3)
      expect(@bolt.plate_type).to eq(:ev)
      expect(@bolt.registration_date).to eq(Date.today)

    end

    it 'tracks collected fees' do
      @facility_1.add_service('Vehicle Registration')
      @facility_1.register_vehicle(@cruz)
      expect(@facility_1.collected_fees).to eq(100)
      @facility_1.register_vehicle(@camaro)
      expect(@facility_1.collected_fees).to eq(125)
      @facility_1.register_vehicle(@bolt)
      expect(@facility_1.collected_fees).to eq(325)
    end

    it 'stores registered vehicles' do
      @facility_1.add_service('Vehicle Registration')
      @facility_1.register_vehicle(@cruz)
      @facility_1.register_vehicle(@camaro)
      @facility_1.register_vehicle(@bolt)
      expect(@facility_1.instance_variable_get(:@registered_vehicles).length).to eq(3)
      expect(@facility_1.instance_variable_get(:@registered_vehicles)).to all be_a(Vehicle)
    end
#upon successful registration
    it 'assigns plate_type to vehicles' do
      @facility_1.add_service('Vehicle Registration')
      @facility_1.register_vehicle(@cruz)
      @facility_1.register_vehicle(@camaro)
      @facility_1.register_vehicle(@bolt)
      expect(@cruz.plate_type).to eq(:regular)
      expect(@camaro.plate_type).to eq(:antique)
      expect(@bolt.plate_type).to eq(:ev)
    end
  end

#license services
  describe '#administer written test' do
    it 'accesses registrant license data' do
      expect(@registrant_1.instance_variable_get(:@license_data).length).to eq(3)
      expect(@registrant_1.permit?).to eq(true)
    end

    it '#does not administer without offering' do
      expect(@facility_1.administer_written_test(@registrant_1)).to eq(false)
    end

    it '#changes hash to true after administering' do
      @facility_1.add_service('Written Test')
      @facility_1.administer_written_test(@registrant_1)
      expect(@registrant_1.license_data[:written]).to eq(true)
    end

    it 'does not administer to under 16' do
      @facility_1.add_service('Written Test')
      @facility_1.administer_written_test(@registrant_3)
      expect(@registrant_3.license_data[:written]).to eq(false)
      @registrant_3.earn_permit
      @facility_1.administer_written_test(@registrant_3)
      expect(@registrant_3.license_data[:written]).to eq(false)
    end

    it 'require permit to administer' do
      @facility_1.add_service('Written Test')
      @facility_1.administer_written_test(@registrant_2)
      expect(@registrant_2.license_data[:written]).to eq(false)
      @registrant_2.earn_permit
      @facility_1.administer_written_test(@registrant_2)
      expect(@registrant_2.license_data[:written]).to eq(true)
    end
  end

  describe '#administer_road_test' do
    it 'only performs if offered and if written test is passed' do
      expect(@facility_1.administer_road_test(@registrant_3)).to eq(false)
      @facility_1.add_service('Road Test')
      expect(@facility_1.administer_road_test(@registrant_3)).to eq(false)
      @registrant_3.earn_permit
      expect(@facility_1.administer_road_test(@registrant_3)).to eq(false)
      @facility_1.add_service('Written Test')
      @facility_1.administer_written_test(@registrant_1)
      @facility_1.administer_road_test(@registrant_1)
      expect(@registrant_1.license_data[:license]).to eq(true)
    end
  end

  describe '#renew_drivers_license' do
    it 'only performs if offered and #registrant has license' do
      expect(@facility_1.renew_drivers_license(@registrant_1)).to eq(false)
      @facility_1.add_service('Renew License')
      @facility_1.add_service('Written Test')
      @facility_1.add_service('Road Test')
      expect(@facility_1.renew_drivers_license(@registrant_1)).to eq(false)
      @facility_1.administer_written_test(@registrant_1)
      expect(@facility_1.renew_drivers_license(@registrant_1)).to eq(false)
      @facility_1.administer_road_test(@registrant_1)
      @facility_1.renew_drivers_license(@registrant_1)
      expect(@registrant_1.license_data[:renewed]).to eq(true)
    end
  end
end
