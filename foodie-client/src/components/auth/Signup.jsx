import {useForm} from 'react-hook-form'
import {useNavigate} from 'react-router-dom'
import axios from 'axios'
import { useEffect } from 'react';

const Signup = () => {
  const { register, handleSubmit, formState: { errors } } = useForm();
  const navigate = useNavigate();
  const API_URL = 'http://localhost:3001'
  //TODO: CREATE AN ERROR MESSAGE FOR INVALID EMAIL. AND PASSWORD CONFIRMATION AND PASSWORD DONT MATCH
  //POTENTIALLY INCORPORATE A HOOK TO HANDLE ERRORS FOR US.
  const onSubmit = (user) => {
    axios.post(`${API_URL}/auth`, {user}, {withCredentials: true})
    .then((res) => {
      if(res.data.status === 'created'){
        localStorage.setItem('accessToken', res.headers['access-token'])
        navigate('/')
      }else {
        console.log(res.data.errors)
      }
    })
  };

  useEffect(() => {
    if (localStorage.getItem('accessToken')) {
      navigate('/')
    }
  })

  return (
    <div className="container object-center mt-36 mb-32pb-64">
      {errors.username && <span>User Name required</span>}
      {errors.email && <span>Email required</span>}
      {errors.password && <span>Password required</span>}
      <h1>New User</h1>
      <form
        className="bg-gray-300 shadow-md rounded px-8 pt-6 pb-8 mb-4"
        onSubmit={handleSubmit(onSubmit)}
      >
        <div>
          <label>Username</label>
          <input
            type="text"
            name="username"
            placeholder="User Name"
            {...register("username", { required: true })}
          />
        </div>
        <br />
        <div>
          <label>Email</label>
          <input
            type="text"
            name="email"
            placeholder="Email"
            {...register("email", { required: true })}
          />
        </div>
        <br />
        <div>
          <label>Password</label>
          <input
            type="password"
            name="password"
            placeholder="Password"
            {...register("password", { required: true })}
          />
        </div>
        <br />
        <div>
          <label>Password Confirmation:</label>
          <input
            type="password"
            name="password_confirmation"
            placeholder="Confirm Password"
            {...register("password_confirmation", { required: true })}
          />
        </div>
        <br />
        <div>
          <button type="submit">Sign Up</button>
        </div>
      </form>
    </div>
  );
}

export default Signup;