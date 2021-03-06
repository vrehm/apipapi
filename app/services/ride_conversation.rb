class RideConversation

  def initialize(request, found_params)
    @request = request
    @ride = @request.service
    @found_params = found_params

    check_addresses
  end

  def answer

    error =     "Je n'ai pas compris votre demande. Pourriez-vous envoyer " \
                "votre demande sous la forme : Je suis au [Adresse de départ, Ville], " \
                "je vais au [Adresse d'arrivée, Ville]"

    if @price
      if @price == "distance_exceeded"
        @answer = "Désolé, la distance entre #{@start_address_nice } " \
                  "à #{@end_address_nice} est supérieure à 100 kilomètres. Veuillez réessayer !"
        @request.update(wait_message: false)
      elsif @price == "no_uber"
        @answer = "Désolé, nous ne trouvons pas de Uber entre #{@start_address_nice } " \
                  "et #{@end_address_nice}."
        @request.update(wait_message: false)
      elsif @request.user.uber_token
        @answer = "Le prix de la course de #{@start_address_nice } " \
                  "à #{@end_address_nice} est de #{@price} (une voiture peut être là " \
                  "dans #{@time} minutes). Envoyez OUI pour commander"
      else
        @answer = "Le prix de la course de #{@start_address_nice } " \
                  "à #{@end_address_nice} est de #{@price} (une voiture peut être là " \
                  "dans #{@time} minutes). Appellez-nous pour créer un compte Uber et commander " \
                  "des chauffeurs partout en Europe."
        @request.update(wait_message: false)
      end
    elsif @time
      if @time.class == Fixnum
        @answer = "Une voiture peut venir vous chercher au #{@start_address_nice} " \
                  "dans #{@time} minutes. Pourriez-vous me renvoyer votre adresse " \
                  "d'arrivée pour que je puisse vous proposer un prix ?"
      else
        @answer = "Désolé, la zone autour de #{@start_address_nice} n'est pas encore couverte !"
      end
    elsif @ride.end_address
      @answer = "Je n'ai pas compris votre adresse de départ. Pourriez-vous " \
                "me la renvoyer en précisant la ville ? "
    else
      @answer = error
    end

    return @answer
  end

  private

  # TODO trouver les bonnes clefs entities (indice ce n'est pas :from et :to)
  def check_addresses

    if location = @found_params.entities.detect {|entity| entity.name == "from"} || @ride.start_address
      if @ride.start_address.nil?
        address = geocode(location.value)
      else
        address = @ride.start_address
      end

        @ride.start_address = address
        @ride.save

        @start_address_nice = Geocoder.search("#{address.latitude},#{address.longitude}").first.formatted_address

        @time_in_seconds = UberService.new(@ride).time_estimates
        @time = @time_in_seconds / 60 if @time_in_seconds.class == Fixnum
    end

    if location = @found_params.entities.detect {|entity| entity.name == "to"} || @ride.end_address
      if @ride.end_address.nil?
        address = geocode(location.value)
      else
        address = @ride.end_address
      end

      @ride.end_address = address
      @ride.save

      @end_address_nice = Geocoder.search("#{address.latitude},#{address.longitude}").first.formatted_address
    end
    if  (location = @found_params.entities.detect {|entity| entity.name == "address"}) && (@ride.end_address || @ride.start_address)

      address = geocode(location.value)
      nice_address = Geocoder.search("#{address.latitude},#{address.longitude}").first.formatted_address

      if @ride.end_address.nil?
        @ride.end_address = address
        @end_address_nice = nice_address
      else
        @ride.start_address = address
        @start_address_nice = nice_address
      end

      @ride.save
    end

    if !@ride.end_address.nil? && !@ride.start_address.nil?
      @price = UberService.new(@ride).price_estimates
    end
  end

  # on utilise pas les lat et lng de Recast, ça fait trop de conditions
  def geocode(searched_address)
    address = Address.new(query: searched_address)
    address.validate # triggers geocoder
    address.save
    return address
  end
end
