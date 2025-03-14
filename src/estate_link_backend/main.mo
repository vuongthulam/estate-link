import Result "mo:base/Result";
import Time "mo:base/Time";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import TrieMap "mo:base/TrieMap";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";

actor REDAO {

    type Result<A, B> = Result.Result<A, B>;

    type Role = {
        #Buyer;
        #Agent;
    };

    type Member = {
        name : Text;
        role : Role;
    };

    type ListingStatus = {
        #Active;
        #Inactive;
        #Sold;
    };

    type PropertyId = Nat;
    type ListedProperty = {
        id : Nat;
        mls : Nat;
        address : Text;
        Features : Text;
        creator : Principal;
        created : Time.Time;
        status : ListingStatus;
        highestBid : Nat;
        highestBidder : ?Principal;
    };

    type HashMap<A, B> = HashMap.HashMap<A, B>;

    var nextPropertyId : Nat = 0;
    let properties = TrieMap.TrieMap<PropertyId, ListedProperty>(Nat.equal, Hash.hash);
    let redao : HashMap<Principal, Member> = HashMap.HashMap<Principal, Member>(0, Principal.equal, Principal.hash);

    public shared ({ caller }) func registerMember(name : Text) : async Result<(), Text> {
        switch (redao.get(caller)) {
            case (?member) return #err("Member already exists");
            case (null) {
                if (redao.size() == 0) {
                    redao.put(
                        caller,
                        {
                            name = name;
                            role = #Agent;
                        },
                    );
                    return #ok();
                };
                redao.put(
                    caller,
                    {
                        name = name;
                        role = #Buyer;
                    },
                );
                return #ok();
            };
        };
    };

    public query func getMember(p : Principal) : async Result<Member, Text> {
        switch (redao.get(p)) {
            case (null) return #err("No member found");
            case (?member) return #ok(member);
        };
    };

    public shared ({ caller }) func becomeAgent(buyer : Principal) : async Result<(), Text> {
        switch (redao.get(caller)) {
            case (?member1) {
                switch (member1.role) {
                    case (#Agent) {
                        switch (redao.get(buyer)) {
                            case (null) return #err("No member found");
                            case (?member2) {
                                switch (member2.role) {
                                    case (#Buyer) {
                                        let newMember = {
                                            name = member2.name;
                                            role = #Agent;
                                        };
                                        redao.put(buyer, newMember);
                                        return #ok();
                                    };
                                    case (#Agent) return #err("Already an Agent");
                                };
                                return #err("You are not a buyer");
                            };
                        };
                    };
                    case (#Buyer) return #err("You are a Buyer; only Agents may do this");
                };
            };
            case (null) return #err("You are not a member");
        };
    };

    func _isMember(p : Principal) : Bool {
        switch (redao.get(p)) {
            case (null) return false;
            case (?member) return true;
        };
    };

    func _isAgent(p : Principal) : Bool {
        switch (redao.get(p)) {
            case (null) return false;
            case (?member) {
                switch (member.role) {
                    case (#Agent) {
                        return true;
                    };
                    case (#Buyer) {
                        return false;
                    };
                };
                return false;
            };
        };
    };

    public shared ({ caller }) func createProperty(address : Text, MLS : Nat) : async Result<PropertyId, Text> {
        if (not _isMember(caller)) {
            return #err("Not a member");
        };

        if (not _isAgent(caller)) return #err("Only Agents can create a Property Listing.");

        let idSaved = nextPropertyId;
        let newProperty : ListedProperty = {
            id = idSaved;
            creator = caller;
            mls = MLS;
            Features = "";
            address = address;
            created = Time.now();
            highestBid = 0;
            highestBidder = null;
            status = #Active;
        };
        properties.put(idSaved, newProperty);

        nextPropertyId += 1;
        return #ok(idSaved);
    };

    public shared ({ caller }) func bidOnProperty(propertyId : PropertyId, bid : Nat) : async Result<(), Text> {
        if (not _isMember(caller)) {
            return #err("Not a member; cannot bid");
        };
        switch (properties.get(propertyId)) {
            case (null) return #err("Property not found");
            case (?property) {
                if (property.status == #Inactive or property.status == #Sold) return #err("Property is not available.");
                if (property.highestBidder == ?caller) {
                    return #err("Already highest bidder.");
                };
                if (property.highestBid >= bid) {
                    let bidText = Nat.toText(bid);
                    let highestBidText = Nat.toText(property.highestBid);
                    return #err("Your bid of " # bidText # " did not exceed the highest bid of " # highestBidText # "!");
                };
                let newProperty : ListedProperty = {
                    id = propertyId;
                    creator = property.creator;
                    mls = property.mls;
                    Features = "";
                    address = property.address;
                    created = property.created;
                    highestBid = bid;
                    highestBidder = ?caller;
                    status = #Active;
                };
                properties.put(property.id, newProperty);
                return #ok();
            };
        };
    };

    public shared ({ caller }) func acceptHighestBidOnProperty(propertyId : PropertyId) : async Result<(), Text> {
        if (not _isMember(caller)) {
            return #err("Not a member");
        };

        if (not _isAgent(caller)) return #err("Only Agents can accept a bid.");

        switch (properties.get(propertyId)) {
            case (null) return #err("Property not found");
            case (?property) {
                let newProperty : ListedProperty = {
                    id = propertyId;
                    mls = property.mls;
                    Features = "";
                    address = property.address;
                    created = property.created;
                    creator = property.creator;
                    highestBid = property.highestBid;
                    highestBidder = property.highestBidder;
                    status = #Sold;
                };
                properties.put(propertyId, newProperty);

                return #ok();
            };
        };
    };

    public shared ({ caller }) func deactivatePropertyListing(propertyId : PropertyId) : async Result<(), Text> {
        if (not _isMember(caller)) {
            return #err("Not a member");
        };

        if (not _isAgent(caller)) return #err("Only Agents can deactivate a property.");

        switch (properties.get(propertyId)) {
            case (null) return #err("Property not found");
            case (?property) {
                let newProperty : ListedProperty = {
                    id = propertyId;
                    mls = property.mls;
                    Features = "";
                    address = property.address;
                    created = property.created;
                    creator = property.creator;
                    highestBid = property.highestBid;
                    highestBidder = property.highestBidder;
                    status = #Inactive;
                };
                properties.put(propertyId, newProperty);

                return #ok();
            };
        };
    };

    public query func getAllProperties() : async [ListedProperty] {
        return Iter.toArray(properties.vals());
    };

    public query func getAllDAOMembers() : async [Member] {
        return Iter.toArray(redao.vals());
    };

    public shared query ({ caller }) func getMyself() : async Principal {
        return caller;
    }

};

