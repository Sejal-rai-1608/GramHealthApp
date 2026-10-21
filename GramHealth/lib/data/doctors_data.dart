class Doctor {
  final String id;
  final String name;
  final String spec;
  final String exp;
  final double rating;
  final String reviews;
  final bool online;
  final String image;
  final String fee;
  final String patients;
  final String about;

  const Doctor({
    required this.id,
    required this.name,
    required this.spec,
    required this.exp,
    required this.rating,
    required this.reviews,
    required this.online,
    required this.image,
    required this.fee,
    required this.patients,
    required this.about,
  });
}

const List<Doctor> kDoctors = [
  Doctor(
    id: '1',
    name: 'Dr. Anita Joshi',
    spec: 'General Physician',
    exp: '12 yrs',
    rating: 4.8,
    reviews: '120+',
    online: true,
    image: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400',
    fee: '₹500',
    patients: '1.2k+',
    about:
        'Dr. Anita Joshi is a highly experienced General Physician based in the district hospital. She specializes in rural healthcare and has been serving the community for over a decade with a focus on preventive medicine.',
  ),
  Doctor(
    id: '2',
    name: 'Dr. Rajesh Kumar',
    spec: 'Pediatrician',
    exp: '15 yrs',
    rating: 4.9,
    reviews: '250+',
    online: true,
    image: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400',
    fee: '₹600',
    patients: '3.5k+',
    about:
        'Dr. Rajesh Kumar is a dedicated Pediatrician known for his gentle approach with children. He has extensive experience in managing childhood illnesses and developmental growth in rural settings.',
  ),
  Doctor(
    id: '3',
    name: 'Dr. Smita Patil',
    spec: 'Dermatologist',
    exp: '8 yrs',
    rating: 4.7,
    reviews: '85+',
    online: false,
    image: 'https://images.unsplash.com/photo-1594824476967-48c8b964273f?w=400',
    fee: '₹700',
    patients: '900+',
    about:
        'Dr. Smita Patil is a skilled Dermatologist specializing in various skin conditions and aesthetic treatments. She is committed to providing modern dermatological care to rural populations.',
  ),
  Doctor(
    id: '4',
    name: 'Dr. Vikram Singh',
    spec: 'Cardiologist',
    exp: '20 yrs',
    rating: 5.0,
    reviews: '500+',
    online: true,
    image: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400',
    fee: '₹1000',
    patients: '5k+',
    about:
        'Dr. Vikram Singh is a premier Cardiologist with two decades of experience in cardiac care. He specializes in heart health management and emergency cardiac interventions for all age groups.',
  ),
];
